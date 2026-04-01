local helpers = require("totalvim.lsp.helpers")

local function on_init(client)
  local path = client.workspace_folders[1].name

  local luarc_json_exists = vim.fn.glob(vim.fs.joinpath(path, ".luarc.json")) ~= ""
  local luarc_jsonc_exists = vim.fn.glob(vim.fs.joinpath(path, ".luarc.jsonc")) ~= ""
  if luarc_json_exists or luarc_jsonc_exists then return end

  client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
    runtime = { version = "LuaJIT" },
    workspace = {
      checkThirdParty = false,
      library = vim.api.nvim_get_runtime_file("", true),
    },
  })
end


return {
  name = "lua_ls",
  on_attach = { helpers.default, helpers.format_on_save },
  on_init = on_init,
  settings = {
    Lua = {
      hint = { enable = true },
    },
  },
}
