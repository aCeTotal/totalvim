-- Unreal Engine C++ support.
--
-- Unreal builds with UnrealBuildTool (UBT), not CMake, and emits no
-- compile_commands.json on its own — so clangd has no include paths/defines and
-- offers zero engine API. UBT's `GenerateClangDatabase` mode produces that database;
-- this module detects `.uproject` projects and exposes a command to (re)generate it,
-- then restarts clangd so the full engine API becomes available in completion.
--
-- The engine lives outside the project, so its location is discovered in order:
--   1. `vim.g.unreal_engine_path`
--   2. `$UE_ROOT`
--   3. the `.uproject`'s "EngineAssociation":
--        - a path      → used directly (absolute or relative to the project)
--        - a GUID       → looked up in ~/.config/Epic/UnrealEngine/Install.ini
--                         (where source/custom builds register themselves)
--        - a version    → the Epic launcher's LauncherInstalled.dat (rare on Linux)
--   4. an engine tree found by walking up from the project (source build layout)
--   5. a scan of common locations for an extracted/source engine, matched by version
--      (Build.version) — the usual Linux case, since there is no Epic launcher and
--      pre-built engines are unzipped by hand. Search roots: `vim.g.unreal_engine_search_dirs`.
-- Target/config/platform default to `<Project>Editor` / `Development` / `Linux` and
-- can be overridden with `vim.g.unreal_target|unreal_config|unreal_platform`.

local M = {}

---@param start string directory to search upward from
---@return string|nil path to the .uproject file
local function find_uproject(start)
  local hit = vim.fs.find(function(name) return name:match("%.uproject$") end, {
    path = start,
    upward = true,
    type = "file",
  })[1]
  return hit
end

---@param uproject string
---@return string|nil
local function engine_association(uproject)
  local ok, lines = pcall(vim.fn.readfile, uproject)
  if not ok then return nil end
  local ok2, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok2 or type(decoded) ~= "table" then return nil end
  return decoded.EngineAssociation
end

-- Source/custom engine builds register a GUID → install-dir mapping here.
---@param guid string
---@return string|nil
local function installed_by_guid(guid)
  local ini = vim.fn.expand("~/.config/Epic/UnrealEngine/Install.ini")
  if vim.fn.filereadable(ini) == 0 then return nil end
  local want = guid:gsub("[{}]", ""):lower()
  for _, line in ipairs(vim.fn.readfile(ini)) do
    local k, v = line:match("^%s*([^=]-)%s*=%s*(.-)%s*$")
    if k and v ~= "" and k:gsub("[{}]", ""):lower() == want then
      return v
    end
  end
  return nil
end

-- Launcher-installed engines: EngineAssociation "5.4" maps to AppName "UE_5.4".
---@param version string
---@return string|nil
local function installed_by_version(version)
  local dat = vim.fn.expand("~/.config/Epic/UnrealEngineLauncher/LauncherInstalled.dat")
  if vim.fn.filereadable(dat) == 0 then return nil end
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(dat), "\n"))
  if not ok or type(decoded) ~= "table" then return nil end
  for _, item in ipairs(decoded.InstallationList or {}) do
    if item.AppName == ("UE_" .. version) and item.InstallLocation then
      return item.InstallLocation
    end
  end
  return nil
end

-- A project embedded in (or beside) an engine source tree: walk up looking for UBT.
---@param start string
---@return string|nil
local function engine_upward(start)
  local cur = start
  while cur and cur ~= "" do
    if vim.fn.filereadable(vim.fs.joinpath(cur, "Engine", "Build", "BatchFiles", "RunUBT.sh")) == 1 then
      return cur
    end
    local parent = vim.fs.dirname(cur)
    if parent == cur then break end
    cur = parent
  end
  return nil
end

-- The "MajorVersion.MinorVersion" of an engine root, from Engine/Build/Build.version.
---@param engine_root string
---@return string|nil
local function engine_version(engine_root)
  local f = vim.fs.joinpath(engine_root, "Engine", "Build", "Build.version")
  if vim.fn.filereadable(f) == 0 then return nil end
  local ok, d = pcall(vim.json.decode, table.concat(vim.fn.readfile(f), "\n"))
  if ok and type(d) == "table" and d.MajorVersion and d.MinorVersion then
    return ("%d.%d"):format(d.MajorVersion, d.MinorVersion)
  end
  return nil
end

-- Linux has no Epic launcher: pre-built engines are unzipped by hand and source builds
-- may be anywhere. Scan common locations (shallow globs, no deep recursion) for engine
-- roots and tag each with its version. Override the roots via `vim.g.unreal_engine_search_dirs`.
---@return { path: string, version: string|nil }[]
local function scan_engines()
  local dirs = vim.g.unreal_engine_search_dirs
    or { "~", "~/UnrealEngine", "~/Unreal", "~/Epic", "~/Games", "~/Downloads", "~/Documents", "~/.local/share", "/opt" }
  local seen, out = {}, {}
  for _, d in ipairs(dirs) do
    local base = vim.fn.expand(d)
    -- <base>, <base>/*, <base>/*/* as the engine root (covers extracted-zip subfolders).
    for _, glob in ipairs({ "", "/*", "/*/*" }) do
      for _, ubt in ipairs(vim.fn.glob(base .. glob .. "/Engine/Build/BatchFiles/RunUBT.sh", true, true)) do
        local root = ubt:gsub("/Engine/Build/BatchFiles/RunUBT%.sh$", "")
        if not seen[root] then
          seen[root] = true
          out[#out + 1] = { path = root, version = engine_version(root) }
        end
      end
    end
  end
  return out
end

---@param uproject string
---@return string|nil engine root
local function resolve_engine(uproject)
  if vim.g.unreal_engine_path and vim.g.unreal_engine_path ~= "" then return vim.g.unreal_engine_path end
  if vim.env.UE_ROOT and vim.env.UE_ROOT ~= "" then return vim.env.UE_ROOT end

  local assoc = engine_association(uproject)
  local want_version
  if type(assoc) == "string" and assoc ~= "" then
    if assoc:find("/") then
      -- Explicit path (absolute or project-relative).
      local p = assoc:match("^/") and assoc or vim.fs.joinpath(vim.fs.dirname(uproject), assoc)
      return (vim.fs.normalize(vim.fn.fnamemodify(p, ":p")):gsub("/$", ""))
    elseif assoc:match("^%d+%.%d+") then
      want_version = assoc:match("^(%d+%.%d+)")
      local hit = installed_by_version(assoc) -- Epic launcher (rare on Linux)
      if hit then return hit end
    else
      local hit = installed_by_guid(assoc) -- registered source/binary build
      if hit then return hit end
    end
  end

  -- Project embedded in an engine source tree.
  local up = engine_upward(vim.fs.dirname(uproject))
  if up then return up end

  -- Scan common locations; prefer the version the project asks for, else the newest.
  local engines = scan_engines()
  if want_version then
    for _, e in ipairs(engines) do
      if e.version == want_version then return e.path end
    end
  end
  table.sort(engines, function(a, b) return (a.version or "") > (b.version or "") end)
  if engines[1] then return engines[1].path end

  return nil
end

function M.generate_clang_db()
  local buf_dir = vim.fn.expand("%:p:h")
  local uproject = find_uproject(buf_dir ~= "" and buf_dir or vim.fn.getcwd())
  if not uproject then
    return vim.notify("No .uproject found upward from the current file", vim.log.levels.ERROR)
  end

  local engine = resolve_engine(uproject)
  if not engine then
    return vim.notify(
      "Unreal engine path unknown. Set `vim.g.unreal_engine_path` or `$UE_ROOT`.",
      vim.log.levels.ERROR
    )
  end

  local project_dir = vim.fs.dirname(uproject)
  local name = vim.fn.fnamemodify(uproject, ":t:r")
  local target = vim.g.unreal_target or (name .. "Editor")
  local config = vim.g.unreal_config or "Development"
  local platform = vim.g.unreal_platform or "Linux"

  local ubt = vim.fs.joinpath(engine, "Engine", "Build", "BatchFiles", "RunUBT.sh")
  if vim.fn.filereadable(ubt) == 0 then
    return vim.notify("UBT not found at " .. ubt, vim.log.levels.ERROR)
  end

  local cmd = { ubt, target, config, platform, "-project=" .. uproject, "-mode=GenerateClangDatabase" }
  vim.notify(("Unreal: generating clang DB (%s %s %s)…"):format(target, config, platform), vim.log.levels.INFO)

  vim.system(cmd, { text = true, cwd = project_dir }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return vim.notify("UBT failed:\n" .. (res.stderr or res.stdout or ""), vim.log.levels.ERROR)
      end
      -- UBT writes compile_commands.json to the project root (some versions to the
      -- engine root); make sure the project root has it so clangd's upward search finds it.
      local at_project = vim.fs.joinpath(project_dir, "compile_commands.json")
      if vim.fn.filereadable(at_project) == 0 then
        local at_engine = vim.fs.joinpath(engine, "compile_commands.json")
        if vim.fn.filereadable(at_engine) == 1 then
          vim.uv.fs_symlink(at_engine, at_project)
        end
      end
      vim.notify("Unreal: compile_commands.json ready — restarting clangd.", vim.log.levels.INFO)
      pcall(vim.cmd, "LspRestart clangd")
    end)
  end)
end

-- Command + keymap
vim.api.nvim_create_user_command("UnrealGenerateClangDB", M.generate_clang_db, {
  desc = "Unreal: generate compile_commands.json via UBT and restart clangd",
})

require("which-key").add({
  { "<leader>u", group = "unreal" },
  { "<leader>ug", M.generate_clang_db, desc = "generate clang database" },
})

-- One-time hint when editing an Unreal C++ file that still lacks a compile database.
local hinted = false
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    if hinted then return end
    local buf_dir = vim.fn.expand("%:p:h")
    if buf_dir == "" then return end
    local uproject = find_uproject(buf_dir)
    if not uproject then return end
    if vim.fs.find("compile_commands.json", { path = buf_dir, upward = true })[1] then return end
    hinted = true
    vim.notify(
      "Unreal project detected without compile_commands.json — run :UnrealGenerateClangDB for full API completion.",
      vim.log.levels.WARN
    )
  end,
})

return M
