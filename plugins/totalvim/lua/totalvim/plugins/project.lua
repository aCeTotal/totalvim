-- Smart quit: open oil file explorer instead of exiting Neovim.
-- When closing the last window, show the project file list instead of quitting.
-- From oil, :q actually exits.
-- <leader>pv opens oil in a new tab so nothing gets closed.

local function open_project_view()
  vim.cmd("tabnew")
  require("oil").open(vim.fn.getcwd())
end

-- Used by smart_close: replace current buffer with oil (no new tab)
local function replace_with_project_view()
  require("oil").open(vim.fn.getcwd())
end

local function is_last_window()
  local wins = vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative == ""
  end, vim.api.nvim_list_wins())
  return #wins <= 1
end

local function is_oil_buffer()
  return (vim.api.nvim_buf_get_name(0)):match("^oil://") ~= nil
end

local function smart_close(opts)
  opts = opts or {}

  -- If already in oil, actually quit
  if is_oil_buffer() then
    vim.cmd("quit" .. (opts.force and "!" or ""))
    return
  end

  -- Write if requested
  if opts.write then
    vim.cmd("write" .. (opts.force and "!" or ""))
  end

  -- If last window, open file explorer instead of quitting
  if is_last_window() then
    if not opts.write and vim.bo.modified and not opts.force then
      vim.notify("Buffer has unsaved changes (use :q! to force)", vim.log.levels.ERROR)
      return
    end
    replace_with_project_view()
  else
    vim.cmd("quit" .. (opts.force and "!" or ""))
  end
end


-- User commands with bang support
vim.api.nvim_create_user_command("SmartQ", function(o) smart_close({ force = o.bang }) end, { bang = true })
vim.api.nvim_create_user_command("SmartWq", function(o) smart_close({ write = true, force = o.bang }) end, { bang = true })

-- Intercept :q, :wq  (typing :q! expands the `q` abbrev before `!` is appended → SmartQ!)
vim.cmd([[cnoreabbrev <expr> q  getcmdtype() == ":" && getcmdline() ==# "q"  ? "SmartQ"  : "q"]])
vim.cmd([[cnoreabbrev <expr> wq getcmdtype() == ":" && getcmdline() ==# "wq" ? "SmartWq" : "wq"]])

-- Normal-mode quit keys
vim.keymap.set("n", "ZZ", function() smart_close({ write = true }) end, { desc = "Save and close (smart)" })
vim.keymap.set("n", "ZQ", function() smart_close({ force = true }) end, { desc = "Force close (smart)" })

-- <leader>pv  →  project file explorer
require("which-key").add({
  { "<leader>p", group = "project" },
  { "<leader>pv", open_project_view, desc = "project file explorer" },
})
