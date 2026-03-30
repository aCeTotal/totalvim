local M = {}

local programs = {}
local lsp_configs = {}
local done = false

local CRITICALITY = { OK = 1, ERROR = 2, WARN = 3, NOTICE = 4 }

---Checks if a program is available in the system `PATH`
---@param program string the program to check
---@return boolean whether the program is in the `PATH`
local function in_path(program)
  return vim.fn.executable(program) == 1
end

local function health_cmp(a, b)
  -- Sort by program name, if same criticality
  if a[4] == b[4] then return a[1] < b[1] end

  -- Sort by criticality otherwise
  return a[4] < b[4]
end

local function health_sort(tbl)
  table.sort(tbl, health_cmp)
end

local function report_table(tbl)
  for _, info in ipairs(tbl) do
    local report_func = info[2]
    local label = info[1]
    local msg = info[3]

    local message = string.format("`%s` %s", label, msg)

    report_func(message)
  end
end

---Performs health checks for all registered LSP configs
local function check_lspconfigs()
  local configs = {}

  vim.health.start("LSP Configurations:")
  for lsp, available in pairs(lsp_configs) do
    if available then
      table.insert(configs, { lsp, vim.health.ok, "is configured", CRITICALITY.OK })
    else
      table.insert(configs, { lsp, vim.health.error, "is not configured", CRITICALITY.ERROR })
    end
  end

  health_sort(configs)
  report_table(configs)
end

---Performs health checks for all registered programs
local function check_programs()
  local binaries = {}

  vim.health.start("Programs in `PATH`:")
  for program, required in pairs(programs) do
    if in_path(program) then
      table.insert(binaries, { program, vim.health.ok, "is installed", CRITICALITY.OK })
    elseif required then
      table.insert(binaries, { program, vim.health.error, "is not installed", CRITICALITY.ERROR })
    else
      table.insert(binaries, { program, vim.health.info, "is not installed", CRITICALITY.NOTICE })
    end
  end

  health_sort(binaries)
  report_table(binaries)
end

---Registers a program for the healthcheck, the program will be searched in the
---`PATH`.
---
---@param program string the name of the program
---@param required_or_filetypes (boolean | string[]) whether the program is required
M.register_program = function(program, required_or_filetypes)
  if type(required_or_filetypes) == "table" then
    M.register_program(program, false)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = required_or_filetypes,
      callback = function()
        M.register_program(program, true)
      end,
    })
    return
  end

  programs[program] = required_or_filetypes
end

---Registers an LSP server for healthcheck
---@param lsp string the name of the LSP server
---@param cmd string|nil the binary command for this LSP
---@param filetypes string[]|nil the filetypes this LSP handles
M.register_lsp = function(lsp, cmd, filetypes)
  lsp_configs[lsp] = true
  if cmd then
    M.register_program(cmd, filetypes or false)
  end
end

---Marks the configuration as completely loaded
M.done = function()
  done = true
end

---Runs all registered health checks, usually called by `:checkhealth`.
M.check = function()
  vim.health.start("totalvim")
  if done then
    vim.health.ok("Config loaded completely")
  else
    vim.health.warn("Config *not* loaded completely")
  end

  check_lspconfigs()
  check_programs()
end

return M
