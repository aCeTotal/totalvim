local helpers = require("totalvim.lsp.helpers")

return {
  name = "clangd",
  on_attach = { helpers.default },
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
}
