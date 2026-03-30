local helpers = require("totalvim.lsp.helpers")

return {
  name = "emmet_ls",
  on_attach = { helpers.keymap },
  filetypes = { "html", "css", "javascriptreact", "typescriptreact" },
}
