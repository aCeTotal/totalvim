-- disable line breaks in gitcommit mode
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.textwidth = 0
  end,
})

-- register keys for neogit
require("which-key").add({
  { "<leader>g", group = "git" },
  { "<leader>gb", group = "blame" },
})

require("totalvim.health").register_program("git", true)

require("totalvim.lazy").add_specs({ {
  "gitsigns.nvim",
  event = "DeferredUIEnter",
  after = function()
    local gitsigns = require("gitsigns")

    gitsigns.setup()

    require("which-key").add({
      { "<leader>gbb", gitsigns.blame, desc = "open file blame" },
      { "<leader>gbi", function() gitsigns.blame_line({ full = true }) end, desc = "show blame info" },
      { "<leader>gbl", gitsigns.toggle_current_line_blame, desc = "toggle current line blame" },
      { "<leader>gw", gitsigns.toggle_word_diff, desc = "toggle word diff" },
    })
  end,
  keys = {
    { "<leader>gbb", desc = "open file blame" },
    { "<leader>gbi", desc = "show blame info" },
    { "<leader>gbl", desc = "toggle current line blame" },
    { "<leader>gw", desc = "toggle word diff" },
  },
}, {
  "neogit",
  after = function()
    local neogit = require("neogit")

    neogit.setup({})
  end,
  keys = {
    { "<leader>gg", "<cmd>:Neogit<cr>", desc = "Neogit status" },
  },
  ft = { "gitcommit" },
}, })
