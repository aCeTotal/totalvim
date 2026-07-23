local helpers = require("totalvim.lsp.helpers")

-- roslyn.nvim ships its own `lsp/roslyn.lua` and auto-enables the "roslyn" client on
-- the `cs`/`razor` filetypes. Its server-path resolver falls back to
-- `Microsoft.CodeAnalysis.LanguageServer`, which roslyn-ls provides on PATH — so no
-- cmd override is needed. We only merge in our shared keymaps and blink completion
-- capabilities before the client starts. Formatting is handled by the LSP itself
-- (conform's format_on_save falls back to it).
require("totalvim.lazy").add_specs({
  {
    "roslyn.nvim",
    ft = { "cs", "razor" },
    before = function()
      vim.lsp.config("roslyn", {
        on_attach = helpers.default,
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })
    end,
  },
})

require("totalvim.health").register_lsp("roslyn", "Microsoft.CodeAnalysis.LanguageServer", { "cs" })

-- roslyn.nvim owns the client lifecycle; skip the generic lspconfig setup loop.
return {
  name = "roslyn",
  activate = function() return false end,
}
