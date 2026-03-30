local M = {}
local _finished = false

--- Completes the configuration by loading all specifications.
--- This *must* be called after all specs have been added.
---
--- After this has been called, there is no way to effectively add more specs.
M.finish = function()
  _finished = true
  require("lz.n").load(require("totalvim.lazy.specs"))
end

---@param specs lz.n.Spec[]
M.add_specs = function(specs)
  if _finished then
    vim.notify("Cannot add specs after totalvim.lazy.finish() has been called", vim.log.levels.WARN)
    return
  end

  vim.list_extend(require("totalvim.lazy.specs"), specs)
end

return M
