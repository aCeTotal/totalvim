local helpers = require("totalvim.helpers")
local luasnip = require("luasnip")
local select = require("luasnip.extras.select_choice")

luasnip.config.setup({ enable_autosnippets = true })


-- Load VSCode-style snippets (from friendly-snippets)
require("luasnip.loaders.from_vscode").lazy_load()

-- Load custom lua snippets
local git_root = helpers.git_root()
local paths = {}
if git_root then
  local snippet_path = vim.fs.joinpath(git_root, "snippets")
  table.insert(paths, snippet_path)
end
table.insert(paths, vim.fn.stdpath("config") .. "/snippets")
require("luasnip.loaders.from_lua").load({ paths = paths })


local function cycle()
  if luasnip.choice_active() then return luasnip.change_choice(1) end
end


require("which-key").add({
  { "<C-e>", luasnip.expand, desc = "expand snippet", mode = { "i", "s" } },
  { "<C-j>", cycle, desc = "cycle choices in node", mode = { "i", "s" } },
  { "<C-S-j>", select, desc = "UI select choices in node", mode = { "i", "s" } },
})
