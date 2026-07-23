-- stylua: ignore start
vim.o.mouse = "a"                -- allow mouse everywhere
vim.o.tabstop = 2                -- \
vim.o.softtabstop = 2            -- |
vim.o.shiftwidth = 2             -- > Set tab behaviour
vim.o.expandtab = true           -- /
vim.o.autoindent = true          -- Auto indent (treesitter indent handles smart indenting)
vim.o.colorcolumn = ""          -- no column markers
vim.o.signcolumn = "yes"         -- always show signcolumn
vim.o.number = true              -- always show line numbers
vim.o.statuscolumn = "%s%=%l    " -- signs + line number + fixed gap before code
vim.o.relativenumber = false     -- explicit disable
vim.o.cursorline = true          -- slightly color the line the cursor is on
vim.o.clipboard = "unnamedplus"  -- yank/delete into system clipboard
vim.o.list = true
vim.o.listchars = "tab:  ,trail:\u{23B5}"
vim.o.wrap = false
vim.o.cmdheight = 0              -- hide command line (noice handles it)
vim.o.termguicolors = true
vim.o.updatetime = 1000          -- CursorHold delay (1s)
-- stylua: ignore end


-- Show diagnostic float when cursor holds on a line with errors/warnings
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
    if #diagnostics > 0 then
      vim.diagnostic.open_float({
        scope = "line",
        focusable = false,
        relative = "editor",
        anchor = "NE",
        row = 0,
        col = vim.api.nvim_get_option_value("columns", {}),
        border = "rounded",
      })
    end
  end,
})


-- Ensure a flake project has an allowed `.envrc` so direnv loads its devShell,
-- i.e. running `nix develop` automatically on first open. Returns the .envrc path
-- (existing or freshly created), or nil when there is no flake to load.
---@param dir string directory to search upward from
---@return string|nil
local function ensure_flake_envrc(dir)
  local envrc = vim.fs.find(".envrc", { path = dir, upward = true })[1]
  if envrc then return envrc end

  local flake = vim.fs.find("flake.nix", { path = dir, upward = true })[1]
  if not flake then return nil end

  local root = vim.fs.dirname(flake)
  local path = root .. "/.envrc"
  local f = io.open(path, "w")
  if not f then return nil end
  -- Plain-direnv equivalent of nix-direnv's `use flake`: re-eval when the flake
  -- changes, and export the devShell env (nix caches the eval, so reopens are fast).
  f:write("watch_file flake.nix flake.lock\neval \"$(nix print-dev-env)\"\n")
  f:close()

  -- direnv blocks a new .envrc until allowed; allow it so DirenvExport can load it.
  vim.system({ "direnv", "allow", root }):wait()
  return path
end


-- Export direnv environment when opening a file in a new project
local last_envrc = nil
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    if buf_name == "" then return end

    local envrc = ensure_flake_envrc(vim.fs.dirname(buf_name))
    if not envrc or envrc == last_envrc then return end

    last_envrc = envrc
    vim.cmd("DirenvExport")
  end,
})


-- Restart LSP servers after direnv reloads the environment
vim.api.nvim_create_autocmd("User", {
  pattern = "DirenvLoaded",
  callback = function()
    -- Nvim 0.12+ ships native ":lsp restart"; older lspconfig used ":LspRestart".
    -- pcall: ":lsp restart" errors when no clients are attached (a no-op case).
    if vim.fn.exists(":LspRestart") == 2 then
      pcall(vim.cmd, "LspRestart")
    else
      pcall(vim.cmd, "lsp restart")
    end
  end,
})


-- Auto-reindent on paste
vim.keymap.set("n", "p", "p=`]", { desc = "Paste and re-indent" })
vim.keymap.set("n", "P", "P=`]", { desc = "Paste above and re-indent" })


---Sets linemode to the requested numbering.
---@param numbering_mode "relative"|"absolute"|"toggle" which mode shall be activated by the keypress
---@return function
local function change_linum_mode(numbering_mode)
  if numbering_mode == "toggle" then
    return function() vim.o.relativenumber = not vim.o.relativenumber end
  elseif numbering_mode == "relative" or numbering_mode == "absolute" then
    local rel = numbering_mode == "relative"
    return function() vim.o.relativenumber = rel end
  end

  local message = string.format("'%s' is not a valid mode", numbering_mode)
  error(message)
end


require("which-key").add({
  { "<leader>#", group = "line numbering modes" },
  { "<leader>##", change_linum_mode("toggle"), desc = "toggle relativenumber" },
  { "<leader>#+", change_linum_mode("relative"), desc = "enable relativenumber" },
  { "<leader>#-", change_linum_mode("absolute"), desc = "disable relativenumber" },
})
