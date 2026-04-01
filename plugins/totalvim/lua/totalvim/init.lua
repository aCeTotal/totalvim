local lazy = require("totalvim.lazy")

---A small helper function to lazily require.
---@param modname string
---@return function
local function rf(modname)
  return function()
    require(modname)
  end
end


local this_module = ...


---A small helper function to require a submodule "relatively"
---@param submodule string
---@return unknown
local function rs(submodule)
  local module_name = string.format("%s.%s", this_module, submodule)
  return require(module_name)
end


--- Load individual plugin specifications by scanning the `plugins` directory.
local function discover_plugins()
  ---@type string[]
  local plugins = {}

  -- Get the directory of the current file
  local current_file = debug.getinfo(1, "S").source:sub(2) -- remove `@` prefix
  local base_dir = vim.fs.dirname(current_file)

  -- plugin folder
  local plugins_dir = vim.fs.joinpath(base_dir, "plugins")

  local candidates = vim.fs.dir(plugins_dir)
  for name, type in candidates do
    if type == "file" and name:match("%.lua$") then
      local module_name = name:gsub("%.lua$", "")
      module_name = string.format("totalvim.plugins.%s", module_name)
      table.insert(plugins, module_name)
    end
  end

  -- sorting *should* not matter, though if it becomes an issue, deterministically
  -- ordered modules will be easier to debug than non-deterministically ordered.
  table.sort(plugins)

  return plugins
end


for _, module in ipairs(discover_plugins()) do
  require(module)
end

rs("lsp") -- LSP and related setup

lazy.finish()

require("totalvim.health").done()
