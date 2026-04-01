local helpers = require("totalvim.lsp.helpers")

return {
  name = "cmake",
  on_attach = { helpers.default },
  cmd = { "cmake-language-server" },
  init_options = { buildDirectory = "build" },
}
