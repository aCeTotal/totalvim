local helpers = require("totalvim.lsp.helpers")

return {
  name = "jsonls",
  on_attach = { helpers.default },
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
}
