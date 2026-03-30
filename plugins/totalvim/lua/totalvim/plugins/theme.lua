require("totalvim.lazy").add_specs({ {
  "catppuccin-nvim",
  event = "DeferredUIEnter",
  after = function()
    require("catppuccin").setup({
      flavour = "mocha",
      integrations = {
        blink_cmp = true,
        noice = true,
        cmp = false,
        which_key = true,
        gitsigns = true,
        treesitter = true,
        flash = true,
        mason = false,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    })

    vim.cmd.colorscheme("catppuccin")
  end,
}, })
