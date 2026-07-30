-- Auto-define new symbols: when diagnostics report an undefined function or
-- variable, ask the attached LSP for a "create/generate/declare/add missing"
-- quickfix and apply it silently. Language-agnostic — works for every language
-- whose server offers such an action (rust-analyzer, tsserver, clangd, ...).
-- One diagnostic per cycle: the applied edit re-fires DiagnosticChanged, which
-- picks up the next one. Each diagnostic message is only attempted once per
-- buffer, so a server without a matching action never causes request loops.

local msg_pats = {
  "[Uu]ndefined",
  "[Uu]ndeclared",
  "[Nn]ot defined",
  "[Cc]annot find",
  "[Cc]annot resolve",
  "[Uu]nresolved",
  "[Dd]oes not exist",
  "[Nn]o such",
}

local title_pats = {
  "^[Cc]reate ",
  "^[Gg]enerate ",
  "^[Dd]eclare ",
  "^[Aa]dd missing ",
}

---@param s string
---@param pats string[]
local function matches(s, pats)
  for _, pat in ipairs(pats) do
    if s:find(pat) then return true end
  end
  return false
end

---Applies a code action, resolving it first if it carries no edit/command yet.
---@param client vim.lsp.Client
---@param action table
local function apply_action(client, action)
  local function run(a)
    if a.edit then vim.lsp.util.apply_workspace_edit(a.edit, client.offset_encoding) end
    if a.command then client:exec_cmd(type(a.command) == "table" and a.command or a) end
  end

  if action.edit or action.command then
    run(action)
  else
    client:request("codeAction/resolve", action, function(err, resolved)
      if not err and resolved then run(resolved) end
    end)
  end
end

---Requests code actions for the diagnostic and applies the first that looks
---like a "define this symbol" fix.
---@param buf integer
---@param diag vim.Diagnostic
local function define_symbol(buf, diag)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(buf) },
    range = {
      start = { line = diag.lnum, character = diag.col },
      ["end"] = { line = diag.end_lnum or diag.lnum, character = diag.end_col or diag.col },
    },
    context = { diagnostics = vim.lsp.diagnostic.from({ diag }), triggerKind = 1 },
  }

  local done = false
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, method = "textDocument/codeAction" })) do
    client:request("textDocument/codeAction", params, function(err, actions)
      if done or err or not actions then return end
      for _, action in ipairs(actions) do
        if matches(action.title or "", title_pats) then
          done = true
          apply_action(client, action)
          return
        end
      end
    end, buf)
  end
end

local attempted = {} ---@type table<integer, table<string, boolean>>

---@param buf integer
local function scan(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].modifiable then return end
  if vim.api.nvim_get_mode().mode:find("^i") then return end

  attempted[buf] = attempted[buf] or {}
  for _, diag in ipairs(vim.diagnostic.get(buf)) do
    if matches(diag.message, msg_pats) and not attempted[buf][diag.message] then
      attempted[buf][diag.message] = true
      define_symbol(buf, diag)
      return
    end
  end
end

local timer = assert(vim.uv.new_timer())
local group = vim.api.nvim_create_augroup("totalvim.autodef", { clear = true })

-- Debounced: diagnostics arrive in bursts while the server catches up.
-- InsertLeave re-triggers the scan that was skipped during insert mode.
vim.api.nvim_create_autocmd({ "DiagnosticChanged", "InsertLeave" }, {
  group = group,
  callback = function(args)
    timer:start(500, 0, vim.schedule_wrap(function() scan(args.buf) end))
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  group = group,
  callback = function(args) attempted[args.buf] = nil end,
})
