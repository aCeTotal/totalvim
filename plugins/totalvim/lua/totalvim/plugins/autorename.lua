-- Auto-rename: edit a function/variable name in place and the definition plus
-- every reference follow along. The identifier under the cursor is snapshotted
-- (normal mode and on InsertEnter, so `ciw` works too); when an insert session
-- leaves it with a different name, the old name is briefly restored and a real
-- LSP textDocument/rename is issued with the new name. Guard: if the new name
-- already resolves to a definition elsewhere, the edit is a switch to another
-- symbol — not a rename — and is left alone.

local ns = vim.api.nvim_create_namespace("totalvim.autorename")
local ident_pat = "^[%a_][%w_]*$"

---@class totalvim.rename.Snap
---@field buf integer
---@field row integer 0-based
---@field col integer 0-based start column
---@field end_col integer
---@field name string
---@field mark integer

local snap ---@type totalvim.rename.Snap?

local function drop_snap()
  if snap then vim.api.nvim_buf_del_extmark(snap.buf, ns, snap.mark) end
  snap = nil
end

---Snapshot the identifier under the cursor, if any.
---@param buf integer
---@return boolean
local function take_snap(buf)
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node or not node:type():find("identifier") then return false end
  local srow, scol, erow, ecol = node:range()
  if srow ~= erow then return false end

  local name = vim.treesitter.get_node_text(node, buf)
  if not name:match(ident_pat) then return false end

  drop_snap()
  snap = {
    buf = buf,
    row = srow,
    col = scol,
    end_col = ecol,
    name = name,
    mark = vim.api.nvim_buf_set_extmark(buf, ns, srow, scol, {}),
  }
  return true
end

---Restore the old name, then ask the server to rename it to the new one.
---@param s totalvim.rename.Snap
---@param client vim.lsp.Client
---@param row integer 0-based row of the edited identifier
---@param col integer 0-based start column
---@param end_col integer
---@param new_name string
local function rename(s, client, row, col, end_col, new_name)
  vim.api.nvim_buf_set_text(s.buf, row, col, row, end_col, { s.name })

  local params = {
    textDocument = { uri = vim.uri_from_bufnr(s.buf) },
    position = { line = row, character = col },
    newName = new_name,
  }
  client:request("textDocument/rename", params, function(err, edit)
    if err or not edit then
      -- Server cannot rename this symbol: put the user's edit back.
      vim.api.nvim_buf_set_text(s.buf, row, col, row, col + #s.name, { new_name })
      return
    end
    vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding)
  end, s.buf)
end

---Check whether the snapshotted identifier changed and act on it.
---@param s totalvim.rename.Snap
local function check(s)
  if not vim.api.nvim_buf_is_valid(s.buf) then return end
  local pos = vim.api.nvim_buf_get_extmark_by_id(s.buf, ns, s.mark, {})
  vim.api.nvim_buf_del_extmark(s.buf, ns, s.mark)
  if #pos == 0 then return end

  local okp, parser = pcall(vim.treesitter.get_parser, s.buf)
  if okp and parser then parser:parse() end
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = s.buf, pos = { pos[1], pos[2] } })
  if not ok or not node or not node:type():find("identifier") then return end
  local srow, scol, erow, ecol = node:range()
  if srow ~= erow then return end

  local new_name = vim.treesitter.get_node_text(node, s.buf)
  if new_name == s.name or not new_name:match(ident_pat) then return end

  local client = vim.lsp.get_clients({ bufnr = s.buf, method = "textDocument/rename" })[1]
  if not client then return end

  local params = {
    textDocument = { uri = vim.uri_from_bufnr(s.buf) },
    position = { line = srow, character = scol },
  }
  local sent = client:request("textDocument/definition", params, function(_, result)
    local defs = result or {}
    if not vim.islist(defs) then defs = { defs } end
    for _, loc in ipairs(defs) do
      local uri = loc.uri or loc.targetUri
      local range = loc.range or loc.targetSelectionRange
      local here = uri == params.textDocument.uri and range and range.start.line == srow
      -- New name is an existing symbol defined elsewhere: a switch, not a rename.
      if not here then return end
    end
    rename(s, client, srow, scol, ecol, new_name)
  end, s.buf)
  if not sent then rename(s, client, srow, scol, ecol, new_name) end
end

local group = vim.api.nvim_create_augroup("totalvim.autorename", { clear = true })

vim.api.nvim_create_autocmd("CursorMoved", {
  group = group,
  callback = function(args)
    if not take_snap(args.buf) then drop_snap() end
  end,
})

-- `ciw`/`cw` delete the word before insert starts: keep the normal-mode
-- snapshot when the cursor still sits inside its old range.
vim.api.nvim_create_autocmd("InsertEnter", {
  group = group,
  callback = function(args)
    if take_snap(args.buf) then return end
    if not snap then return end
    local cur = vim.api.nvim_win_get_cursor(0)
    local keep = snap.buf == args.buf and cur[1] - 1 == snap.row and cur[2] >= snap.col and cur[2] <= snap.end_col
    if not keep then drop_snap() end
  end,
})

-- Give the server time to receive the didChange before we query it.
vim.api.nvim_create_autocmd("InsertLeave", {
  group = group,
  callback = function()
    local s = snap
    snap = nil
    if s then vim.defer_fn(function() check(s) end, 300) end
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  group = group,
  callback = function(args)
    if snap and snap.buf == args.buf then snap = nil end
  end,
})
