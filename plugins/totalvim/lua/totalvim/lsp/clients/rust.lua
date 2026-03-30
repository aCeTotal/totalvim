local helpers = require("totalvim.lsp.helpers")

require("totalvim.lazy").add_specs({
  {
    "crates.nvim",
    after = function()
      require("crates").setup({
        lsp = {
          enabled = true,
          on_attach = helpers.default,
          actions = true,
          completion = true,
          hover = true,
        },
      })
    end,
    ft = { "toml" },
  },
})

local settings = {
  ["rust-analyzer"] = {
    inlayHints = {
      typeHints = { enable = true },
      chainingHints = { enable = true },
      bindingModeHints = { enable = true },
      closureReturnTypeHints = { enable = "always" },
      lifetimeElisionHints = { enable = "always" },
      maxLength = 5,
      enable = true,
    },
    lens = { enable = true },
    checkOnSave = {
      command = "clippy",
      allFeatures = true,
    },
  },
}

return {
  name = "rust_analyzer",
  on_attach = { helpers.default, helpers.format_on_save },
  settings = settings,
}
