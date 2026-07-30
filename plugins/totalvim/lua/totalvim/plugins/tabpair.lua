-- Companion tabs: opening a source file also opens its header in its own tab,
-- and vice versa, keeping focus where you were. Lookup: same-named file with a
-- sibling extension next to the file or across src/ <-> include/; for C-family
-- buffers clangd's switchSourceHeader extension takes over once attached
-- (exact, project-aware). Only languages with paired files have entries here —
-- extend `exts` to teach it more. Fires once per buffer, so closing the
-- companion tab does not reopen it.

local exts = {
  c = { "h" },
  cpp = { "hpp", "hh", "hxx", "h" },
  cc = { "hh", "hpp", "h" },
  cxx = { "hxx", "hpp", "h" },
  m = { "h" },
  mm = { "h" },
  h = { "c", "cpp", "cc", "cxx", "m", "mm" },
  hpp = { "cpp", "cc", "cxx" },
  hh = { "cc", "cpp" },
  hxx = { "cxx", "cpp" },
}

---Is the file already shown in some window (any tabpage)?
---@param path string
local function visible(path)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == path then return true end
  end
  return false
end

---Open the companion in its own tab and jump back.
---@param buf integer
---@param path string
local function open_tab(buf, path)
  vim.b[buf].totalvim_tabpair = true
  if visible(path) then return end
  local cur = vim.api.nvim_get_current_tabpage()
  vim.cmd.tabedit(vim.fn.fnameescape(path))
  vim.api.nvim_set_current_tabpage(cur)
end

---Find a companion on disk: same basename with a sibling extension, next to
---the file or with src/ and include/ swapped.
---@param base string path without extension
---@param candidates string[]
---@return string|nil
local function find_companion(base, candidates)
  local bases = { base }
  local inc = base:gsub("/src/", "/include/")
  if inc ~= base then bases[#bases + 1] = inc end
  local src = base:gsub("/include/", "/src/")
  if src ~= base then bases[#bases + 1] = src end

  for _, ext in ipairs(candidates) do
    for _, b in ipairs(bases) do
      local path = b .. "." .. ext
      if vim.uv.fs_stat(path) then return path end
    end
  end
  return nil
end

---@param buf integer
local function try(buf)
  if vim.b[buf].totalvim_tabpair or vim.bo[buf].buftype ~= "" then return end
  local path = vim.api.nvim_buf_get_name(buf)
  local base, ext = path:match("^(.*)%.(%w+)$")
  local candidates = ext and exts[ext:lower()]
  if not candidates then return end

  local clangd = vim.lsp.get_clients({ bufnr = buf, name = "clangd" })[1]
  if clangd then
    clangd:request("textDocument/switchSourceHeader", { uri = vim.uri_from_bufnr(buf) }, function(err, result)
      if not err and result and result ~= vim.NIL then
        open_tab(buf, vim.uri_to_fname(result))
      else
        local found = find_companion(base, candidates)
        if found then open_tab(buf, found) end
      end
    end, buf)
    return
  end

  local found = find_companion(base, candidates)
  if found then open_tab(buf, found) end
end

local group = vim.api.nvim_create_augroup("totalvim.tabpair", { clear = true })

-- nested: the companion's own FileType/LSP autocmds must still fire.
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = group,
  nested = true,
  callback = function(args) try(args.buf) end,
})

-- clangd usually attaches after BufWinEnter; retry with its exact answer if
-- the filesystem lookup found nothing.
vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  nested = true,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "clangd" then try(args.buf) end
  end,
})
