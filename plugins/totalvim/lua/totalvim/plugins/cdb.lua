-- Auto-generate compile_commands.json for plain Makefile projects so clangd
-- always sees the project's real compile flags (includes, defines). CMake and
-- meson projects emit their own database and are left alone. Runs `bear -- make`
-- in the background and restarts the LSP when the database is ready.

local uv = vim.uv

---@type table<string, boolean> roots with a generation currently running
local running = {}
---@type table<string, integer> root -> makefile stamp already attempted
local attempted = {}


---@param path string
---@return integer mtime in seconds, 0 when the file is missing
local function mtime(path)
  local stat = uv.fs_stat(path)
  return stat and stat.mtime.sec or 0
end


---Newest mtime of the files that define the build flags.
---@param root string
---@return integer
local function makefile_stamp(root)
  local stamp = 0
  for _, name in ipairs({ "Makefile", "makefile", "GNUmakefile", "config.mk" }) do
    stamp = math.max(stamp, mtime(vim.fs.joinpath(root, name)))
  end
  return stamp
end


---Nearest Makefile project root for a file. Roots owned by CMake or meson are
---skipped — those build systems generate their own compile database.
---@param file string
---@return string|nil
local function makefile_root(file)
  local makefile = vim.fs.find(
    { "Makefile", "makefile", "GNUmakefile" },
    { path = vim.fs.dirname(file), upward = true }
  )[1]
  if not makefile then return nil end

  local root = vim.fs.dirname(makefile)
  if uv.fs_stat(vim.fs.joinpath(root, "CMakeLists.txt")) then return nil end
  if uv.fs_stat(vim.fs.joinpath(root, "meson.build")) then return nil end
  return root
end


---Regenerates the compile database when it is missing or older than the
---Makefile. `make -B` forces a full rebuild so bear records every compile.
---@param root string
local function generate(root)
  local stamp = makefile_stamp(root)
  local cdb = vim.fs.joinpath(root, "compile_commands.json")
  if mtime(cdb) >= stamp then return end
  if running[root] or attempted[root] == stamp then return end
  if vim.fn.executable("make") ~= 1 then return end

  running[root] = true
  vim.notify("Generating compile_commands.json in " .. root, vim.log.levels.INFO)

  local jobs = tostring(uv.available_parallelism())
  vim.system(
    { "bear", "--output", cdb, "--", "make", "-B", "-j", jobs },
    { cwd = root },
    vim.schedule_wrap(function(result)
      running[root] = nil
      attempted[root] = stamp

      if result.code == 0 and uv.fs_stat(cdb) then
        -- Same restart dance as the DirenvLoaded handler in misc.lua.
        if vim.fn.exists(":LspRestart") == 2 then
          pcall(vim.cmd, "LspRestart")
        else
          pcall(vim.cmd, "lsp restart")
        end
        vim.notify("compile_commands.json ready, LSP restarted", vim.log.levels.INFO)
      else
        local tail = vim.trim((result.stderr or ""):sub(-300))
        vim.notify("bear/make failed:\n" .. tail, vim.log.levels.WARN)
      end
    end)
  )
end


local function check_buffer(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then return end

  local root = makefile_root(file)
  if root then generate(root) end
end


vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function(args) check_buffer(args.buf) end,
})

-- direnv brings make/pkg-config into the environment after the first attempt
-- may have failed without them — clear the attempt log and retry.
vim.api.nvim_create_autocmd("User", {
  pattern = "DirenvLoaded",
  callback = function()
    attempted = {}
    if vim.tbl_contains({ "c", "cpp" }, vim.bo.filetype) then check_buffer(0) end
  end,
})
