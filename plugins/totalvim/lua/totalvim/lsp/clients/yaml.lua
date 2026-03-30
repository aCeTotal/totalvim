local helpers = require("totalvim.lsp.helpers")

return {
  name = "yamlls",
  on_attach = { helpers.default },
  settings = {
    yaml = {
      schemas = require("schemastore").yaml.schemas(),
      validate = true,
      hover = true,
      completion = true,
    },
  },
}
