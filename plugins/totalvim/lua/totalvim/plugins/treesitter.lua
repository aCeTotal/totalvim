-- Treesitter grammars are provided by Nix (withAllGrammars).
-- Enable highlight and indent via built-in vim.treesitter APIs.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

vim.treesitter.language.register("bash", "zsh")
