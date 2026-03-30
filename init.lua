-- Minimal fallback for development without Nix.
-- When built with Nix, plugins/totalvim/plugin/totalvim.lua is the entry point.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("totalvim")
