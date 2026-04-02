-- Smart quit: open oil file explorer instead of exiting Neovim.
-- When closing the last window, show the project file list instead of quitting.
-- From oil, :q actually exits.
-- <leader>pv opens oil in a new tab so nothing gets closed.

local function open_project_view()
  vim.cmd("tabnew")
  require("oil").open(vim.fn.getcwd())
end

local function is_oil_buffer()
  return (vim.api.nvim_buf_get_name(0)):match("^oil://") ~= nil
end

local function count_real_wins()
  return #vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative == ""
  end, vim.api.nvim_list_wins())
end

-- Intercept all quit operations via QuitPre. If the last window is about to
-- close and we're not in oil, keep vim alive by opening oil in a new tab.
-- Works for :q, :q!, :wq, :x, ZZ, ZQ, and any other quit variant.
vim.api.nvim_create_autocmd("QuitPre", {
  nested = true,
  callback = function()
    -- From oil, let vim exit normally
    if is_oil_buffer() then return end

    -- Multiple windows/tabs open: normal quit just closes the current one
    if count_real_wins() > 1 then return end

    -- Last window: create an oil tab so vim survives the quit
    local orig_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabnew")
    require("oil").open(vim.fn.getcwd())
    local oil_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabprev")

    -- If the quit fails (e.g. unsaved changes), clean up the spare tab
    vim.schedule(function()
      if vim.api.nvim_tabpage_is_valid(orig_tab) and vim.api.nvim_tabpage_is_valid(oil_tab) then
        vim.cmd("tabclose " .. vim.api.nvim_tabpage_get_number(oil_tab))
      end
    end)
  end,
})

-- <leader>pv  →  project file explorer
require("which-key").add({
  { "<leader>p", group = "project" },
  { "<leader>pv", open_project_view, desc = "project file explorer" },
})
