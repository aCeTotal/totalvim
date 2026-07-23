-- Keep open buffers in sync with the outside world.
--
-- Whenever a background process changes a file on disk (formatters, code generation,
-- git operations, direnv-driven rebuilds, an Unreal clang-database regen, …) the open
-- buffer is reloaded so both the buffer and the LSP attached to it see the current
-- contents. Reloading re-syncs the document to the language server automatically.
--
-- Complementary refresh paths already live where the change originates:
--   * environment changes  → LSP restart on `User DirenvLoaded` (plugins/misc.lua)
--   * Unreal compile DB     → `:UnrealGenerateClangDB` restarts clangd (plugins/unreal.lua)
--   * project manifests      → servers watch their own files (Cargo.toml,
--                              compile_commands.json, pom.xml, …) and re-index on change.

vim.o.autoread = true

local group = vim.api.nvim_create_augroup("totalvim.refresh", { clear = true })

-- Poll for external changes on idle and when returning to a buffer/window. updatetime
-- (1s, set in misc.lua) makes CursorHold a lightweight heartbeat. Insert-mode idle is
-- intentionally excluded so an active edit is never clobbered.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave" }, {
  group = group,
  callback = function()
    -- Only real, on-disk file buffers; skip the command-line window and special buffers.
    if vim.fn.getcmdwintype() ~= "" or vim.bo.buftype ~= "" then return end
    pcall(vim.cmd.checktime)
  end,
})

-- Surface reloads triggered by a background change so they are never silent surprises.
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = group,
  callback = function()
    vim.notify("Buffer reloaded — file changed on disk.", vim.log.levels.INFO)
  end,
})
