require("conform").setup({
  formatters_by_ft = {
    c = { "clang-format" },
    cpp = { "clang-format" },
    html = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    lua = { "stylua" },
  },
  format_on_save = {
    timeout_ms = 1000,
    lsp_fallback = true,
  },
})



require("totalvim.health").register_program("prettier", { "html", "css", "javascript", "typescript" })
require("totalvim.health").register_program("clang-format", { "c", "cpp" })
require("totalvim.health").register_program("stylua", { "lua" })
