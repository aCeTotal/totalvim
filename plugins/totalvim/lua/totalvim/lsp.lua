local helpers = require("totalvim.lsp.helpers")
local health = require("totalvim.health")
local lspconfig = require("lspconfig")

local blink_capabilities = require("blink.cmp").get_lsp_capabilities({
  textDocument = {
    foldingRange = {
      dynamicRegistration = true,
      lineFoldingOnly = true,
    },
  },
})

-- Load individual languages configuration by scanning clients directory
local function discover_clients()
  local clients = {}
  -- Get the directory of the current file and append "clients"
  local current_file = debug.getinfo(1, "S").source:sub(2) -- Remove the '@' prefix
  local base_dir = vim.fn.fnamemodify(current_file, ":h")
  local client_dir = vim.fs.joinpath(base_dir, "lsp", "clients")

  -- Scan the clients directory for Lua files
  local scan = vim.uv.fs_scandir(client_dir)
  if not scan then
    local message = string.format("unable to scan '%s' for LSP clients", client_dir)
    vim.notify(message)
    return clients
  end

  while true do
    local name, type = vim.uv.fs_scandir_next(scan)
    if not name then break end
    if type == "file" and name:match("%.lua$") then
      -- Convert filename to module path (remove .lua extension)
      local module_name = name:gsub("%.lua$", "")
      local full_module_name = string.format("totalvim.lsp.clients.%s", module_name)
      table.insert(clients, full_module_name)
    end
  end

  -- sorting *should* not matter, though if it becomes an issue, deterministically
  -- ordered modules will be easier to debug than non-deterministically ordered.
  table.sort(clients)

  return clients
end

local clients = discover_clients()

for _, client_module in ipairs(clients) do
  local client_config = require(client_module)

  -- Extract required fields with validation
  local name = client_config.name or error(string.format("client name is required in %s", client_module))

  -- Shortcircuit if LS should not be loaded
  if client_config.activate and not client_config.activate() then
    goto continue
  end

  local capabilities = client_config.capabilities or blink_capabilities
  if type(capabilities) == "function" then
    capabilities = capabilities(vim.deepcopy(blink_capabilities))
  end

  -- Create setup table with defaults applied
  local setup = {
    on_attach = helpers.combine(client_config.on_attach or { helpers.default }),
    capabilities = capabilities,
    init_options = client_config.init_options,
    root_dir = client_config.root_dir,
    cmd = client_config.cmd,
    settings = client_config.settings,
    on_init = client_config.on_init,
    filetypes = client_config.filetypes,
  }

  lspconfig[name].setup(setup)
  health.register_lsp(name, setup.cmd and setup.cmd[1], setup.filetypes)

  ::continue::
end
