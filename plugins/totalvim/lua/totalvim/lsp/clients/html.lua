local helpers = require("totalvim.lsp.helpers")

return {
  name = "html",
  on_attach = { helpers.keymap },
  init_options = {
    provideFormatter = true,
  },
}
