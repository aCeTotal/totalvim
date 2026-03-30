---Refreshes the codelenses in the current buffer
---@param client vim.lsp.Client
---@param buffer integer
---@return function
local function refresh_codelens(client, buffer)
  return function(args)
    if client:supports_method("textDocument/codelens", buffer) then vim.lsp.codelens.refresh(args) end
  end
end

---Triggers a reformat of the current buffer
local function format_buffer()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ async = true, lsp_fallback = true })
  else
    vim.lsp.buf.format({ async = true })
  end
end

---Registers the default keymap for LSP powered buffers
---@param client vim.lsp.Client
---@param buffer integer
local function keymap(client, buffer) ---@diagnostic disable-line:unused-local
  require("which-key").add({
    { "<leader>l", group = "language server" },
    { "<leader>lg", group = "goto" },
    { "<leader>lgD", vim.lsp.buf.declaration, desc = "jump to declaration" },
    { "<leader>lgd", vim.lsp.buf.definition, desc = "jump to definition" },
    { "<leader>lgt", vim.lsp.buf.type_definition, desc = "jump to type definition" },
    { "<leader>lh", vim.lsp.buf.hover, desc = "show hover info" },
    { "<leader>ls", vim.lsp.buf.signature_help, desc = "show signature info" },
    { "<leader>lr", vim.lsp.buf.rename, desc = "rename symbol" },
    { "<leader>lf", format_buffer, desc = "format buffer" },
    { "<leader>l.", vim.lsp.buf.code_action, desc = "show code actions" },
  })
end

---The default LSP attach handler
---@param client vim.lsp.Client
---@param buffer integer
local function default(client, buffer)
  keymap(client, buffer)

  vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "CursorHold", "LspAttach" }, {
    buffer = buffer,
    callback = refresh_codelens(client, buffer),
  })

  vim.api.nvim_exec_autocmds("User", { pattern = "LspAttached" })

  if client.server_capabilities.inlayHintProvider then vim.lsp.inlay_hint.enable(true, { bufnr = buffer }) end
end

---Sets up format-on-save for a buffer
---@param _ vim.lsp.Client
---@param buffer integer
local function format_on_save(_, buffer)
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = buffer,
    callback = function()
      vim.lsp.buf.format({ async = false, bufnr = buffer })
    end,
  })
end

---Iterates over all given handlers and calls them in order
---@param handler function|function[]
---@return function
local function combine(handler)
  if type(handler) ~= "table" then handler = { handler } end

  return function(client, buffer)
    for _, handle_fun in ipairs(handler) do
      handle_fun(client, buffer)
    end
  end
end

return {
  combine = combine,
  default = default,
  format_on_save = format_on_save,
  keymap = keymap,
}
