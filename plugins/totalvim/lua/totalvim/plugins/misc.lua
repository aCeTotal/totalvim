-- stylua: ignore start
vim.o.mouse = "a"                -- allow mouse everywhere
vim.o.tabstop = 2                -- \
vim.o.softtabstop = 2            -- |
vim.o.shiftwidth = 2             -- > Set tab behaviour
vim.o.expandtab = true           -- /
vim.o.autoindent = true          -- Auto indent
vim.o.smartindent = true
vim.o.colorcolumn = ""          -- no column markers
vim.o.signcolumn = "yes"         -- always show signcolumn
vim.o.number = true              -- always show line numbers
vim.o.statuscolumn = "%s%=%l  "   -- signs + line number + fixed gap before code
vim.o.relativenumber = false     -- explicit disable
vim.o.cursorline = true          -- slightly color the line the cursor is on
vim.o.cursorcolumn = true        -- slightly color the column the cursor is on
vim.o.clipboard = "unnamedplus"  -- yank/delete into system clipboard
vim.o.list = true
vim.o.listchars = "tab:  ,trail:\u{23B5}"
vim.o.wrap = false
vim.o.cmdheight = 0              -- hide command line (noice handles it)
vim.o.termguicolors = true
vim.o.updatetime = 2000          -- CursorHold delay (2s)
-- stylua: ignore end

-- Auto-allow direnv when .envrc exists
vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
  callback = function()
    if vim.fn.filereadable(".envrc") == 1 then
      vim.fn.system("direnv allow")
    end
  end,
})

-- Show diagnostic float when cursor holds on a line with errors/warnings
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
    if #diagnostics > 0 then
      vim.diagnostic.open_float({
        scope = "cursor",
        focusable = false,
        relative = "editor",
        anchor = "NE",
        row = 0,
        col = vim.o.columns,
        border = "rounded",
      })
    end
  end,
})

-- Auto-reindent on paste
vim.keymap.set("n", "p", "p=`]", { desc = "Paste and re-indent" })
vim.keymap.set("n", "P", "P=`]", { desc = "Paste above and re-indent" })

---Sets linemode to the requested numbering.
---@param numbering_mode "relative"|"absolute"|"toggle" which mode shall be activated by the keypress
---@return function
local function change_linum_mode(numbering_mode)
  if numbering_mode == "toggle" then
    return function() vim.o.relativenumber = not vim.o.relativenumber end
  elseif numbering_mode == "relative" or numbering_mode == "absolute" then
    local rel = numbering_mode == "relative"
    return function() vim.o.relativenumber = rel end
  end

  local message = string.format("'%s' is not a valid mode", numbering_mode)
  error(message)
end

require("which-key").add({
  { "<leader>#", group = "line numbering modes" },
  { "<leader>##", change_linum_mode("toggle"), desc = "toggle relativenumber" },
  { "<leader>#+", change_linum_mode("relative"), desc = "enable relativenumber" },
  { "<leader>#-", change_linum_mode("absolute"), desc = "disable relativenumber" },
})
