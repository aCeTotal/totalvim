local helpers = require("totalvim.lsp.helpers")

return {
  name = "cssls",
  on_attach = { helpers.keymap },
  settings = {
    css = { validate = true },
    scss = { validate = true },
    less = { validate = true },
  },
}
