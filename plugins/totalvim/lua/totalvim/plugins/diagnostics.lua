-- Instant syntax feedback: show diagnostics inline and while still typing.
-- Nvim defaults hide virtual text (0.11+) and defer display until InsertLeave;
-- both defeat "tell me the moment I miss a ;".
vim.diagnostic.config({
  update_in_insert = true,
  virtual_text = {
    prefix = "\u{25CF}",
    spacing = 2,
  },
  severity_sort = true,
})
