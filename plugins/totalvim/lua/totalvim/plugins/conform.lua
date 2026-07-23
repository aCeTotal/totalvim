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
    java = { "google-java-format" },
    nix = { "nixfmt" },
  },
  format_on_save = {
    timeout_ms = 1000,
    lsp_fallback = true,
  },
})



require("totalvim.health").register_program("prettier", { "html", "css", "javascript", "typescript" })
require("totalvim.health").register_program("clang-format", { "c", "cpp" })
require("totalvim.health").register_program("stylua", { "lua" })
require("totalvim.health").register_program("google-java-format", { "java" })
require("totalvim.health").register_program("nixfmt", { "nix" })
