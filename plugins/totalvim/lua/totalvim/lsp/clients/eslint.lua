local helpers = require("totalvim.lsp.helpers")

local function on_attach(_, buffer)
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = buffer,
    command = "EslintFixAll",
  })
end

return {
  name = "eslint",
  on_attach = { helpers.keymap, on_attach },
}
