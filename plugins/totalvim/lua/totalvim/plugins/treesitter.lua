-- Treesitter grammars are provided by Nix (withAllGrammars).
-- Must explicitly enable highlight and indent for all filetypes.
require("nvim-treesitter.configs").setup({
  highlight = { enable = true },
  indent = { enable = true },
})

vim.treesitter.language.register("bash", "zsh")
