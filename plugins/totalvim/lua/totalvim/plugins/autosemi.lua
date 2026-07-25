-- Auto-insert ";" where the grammar proves one is missing. Tree-sitter error
-- recovery adds a zero-width MISSING ";" node at the exact spot it was expected,
-- so this never guesses: builder chains like `foo()\n.bar()` parse fine and
-- produce no missing node. Fires only when the cursor leaves a line.
local fts = { c = true, cpp = true, rust = true, cs = true, java = true }


---Column of a MISSING ";" node on `row`, or nil if the line parses clean.
---@param buf integer
---@param row integer 0-based
---@return integer|nil col
---@return TSNode|nil root
local function missing_semi_col(buf, row)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or not parser then return nil end
  local tree = parser:parse()[1]
  if not tree then return nil end

  local root = tree:root()
  local stack = { root }
  while #stack > 0 do
    local node = table.remove(stack)
    local srow, scol, erow = node:range()
    if srow <= row and row <= erow then
      if node:missing() and node:type() == ";" and srow == row then
        return scol, root
      end
      for child in node:iter_children() do
        stack[#stack + 1] = child
      end
    end
  end
  return nil
end


---The MISSING node lands after trailing comments/whitespace; walk the insert
---point back so the ";" ends up right after the last code token.
---@param root TSNode
---@param line string
---@param row integer
---@param col integer
---@return integer
local function before_trailing_trivia(root, line, row, col)
  while col > 0 do
    local node = root:descendant_for_range(row, col - 1, row, col)
    if node and node:type():match("comment") then
      local srow, scol = node:range()
      if srow ~= row then break end
      col = scol
    elseif line:sub(col, col):match("%s") then
      col = col - 1
    else
      break
    end
  end
  return col
end


---@param buf integer
---@param row integer 0-based
local function fix(buf, row)
  if not fts[vim.bo[buf].filetype] or not vim.bo[buf].modifiable then return end
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  if not line or line:match("^%s*$") or line:match(";%s*$") then return end

  local col, root = missing_semi_col(buf, row)
  if col and root then
    col = before_trailing_trivia(root, line, row, col)
    vim.api.nvim_buf_set_text(buf, row, col, row, col, { ";" })
  end
end


local group = vim.api.nvim_create_augroup("totalvim.autosemi", { clear = true })
local last_row = {}

vim.api.nvim_create_autocmd("InsertEnter", {
  group = group,
  callback = function(args)
    last_row[args.buf] = vim.api.nvim_win_get_cursor(0)[1] - 1
  end,
})

-- Catch <CR> and other in-insert line changes: fix the line that was left.
vim.api.nvim_create_autocmd("CursorMovedI", {
  group = group,
  callback = function(args)
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local prev = last_row[args.buf]
    last_row[args.buf] = row
    if prev and prev ~= row then fix(args.buf, prev) end
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = group,
  callback = function(args)
    fix(args.buf, vim.api.nvim_win_get_cursor(0)[1] - 1)
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  group = group,
  callback = function(args)
    last_row[args.buf] = nil
  end,
})
