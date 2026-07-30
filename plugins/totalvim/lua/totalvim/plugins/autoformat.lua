-- Full-file autoformat: reformat the whole buffer whenever the cursor leaves
-- a line in insert mode (<CR>), when leaving insert, and after normal-mode
-- edits. Async, so typing is never blocked; conform discards the result if
-- the buffer changed before the formatter finished. A no-change format applies
-- no edits and fires no TextChanged, so this cannot loop.
local timer = assert(vim.uv.new_timer())

---@param buf integer
local function format(buf)
  timer:start(
    150,
    0,
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].modifiable then return end
      require("conform").format({ bufnr = buf, async = true, lsp_fallback = true })
    end)
  )
end

local group = vim.api.nvim_create_augroup("totalvim.autoformat", { clear = true })
local last_row = {}

vim.api.nvim_create_autocmd("InsertEnter", {
  group = group,
  callback = function(args) last_row[args.buf] = vim.api.nvim_win_get_cursor(0)[1] end,
})

-- <CR> and other in-insert line changes.
vim.api.nvim_create_autocmd("CursorMovedI", {
  group = group,
  callback = function(args)
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local prev = last_row[args.buf]
    last_row[args.buf] = row
    if prev and prev ~= row then format(args.buf) end
  end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  group = group,
  callback = function(args) format(args.buf) end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  group = group,
  callback = function(args) last_row[args.buf] = nil end,
})
