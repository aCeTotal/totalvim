local helpers = require("totalvim.lsp.helpers")

return {
  name = "taplo",
  on_attach = { helpers.default },
  settings = {
    taplo = {
      diagnostics = { enabled = true },
      completion = { enabled = true },
      schema = {
        enabled = true,
        associations = {},
      },
    },
  },
}
