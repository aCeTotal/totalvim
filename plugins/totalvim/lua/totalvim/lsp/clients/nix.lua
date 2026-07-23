local helpers = require("totalvim.lsp.helpers")

-- Formatting is handled by conform (nixfmt), matching the C/C++ pattern.
return {
  name = "nixd",
  on_attach = { helpers.default },
  cmd = { "nixd" },
}
