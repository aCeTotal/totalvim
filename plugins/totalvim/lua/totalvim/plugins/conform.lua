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


-- Auto-format on file open
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local conform = require("conform")
    local ft = vim.bo[args.buf].filetype
    if ft ~= "" and conform.list_formatters(args.buf)[1] then
      conform.format({ bufnr = args.buf, timeout_ms = 1000, lsp_fallback = true })
    end
  end,
})


require("totalvim.health").register_program("prettier", { "html", "css", "javascript", "typescript" })
require("totalvim.health").register_program("clang-format", { "c", "cpp" })
require("totalvim.health").register_program("stylua", { "lua" })
