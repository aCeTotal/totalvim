require("totalvim.lazy").add_specs({ {
  "bigfile.nvim",
  event = "DeferredUIEnter",
  after = function()
    require("bigfile").setup({
      filesize = 512,
      pattern = { "*" },
      features = {
        "indent_blankline",
        "illuminate",
        "lsp",
        "treesitter",
        "syntax",
        "matchparen",
        "vimopts",
        "filetype",
      },
    })
  end,
}, })
