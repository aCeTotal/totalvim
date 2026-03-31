vim.o.foldcolumn = "0"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.o.fillchars = "foldopen:\u{256D},foldclose:\u{00B7},foldsep:\u{2502}"

require("totalvim.lazy").add_specs({ {
  "nvim-ufo",
  event = "DeferredUIEnter",
  after = function()
    local ufo = require("ufo")
    ufo.setup({
      provider_selector = function()
        return { "lsp", "indent" }
      end,
    })

    require("which-key").add({
      { "zR", ufo.openAllFolds, desc = "open all folds" },
      { "zM", ufo.closeAllFolds, desc = "close all folds" },
    })
  end,
  keys = {
    { "zR", desc = "open all folds" },
    { "zM", desc = "close all folds" },
  },
}, })
