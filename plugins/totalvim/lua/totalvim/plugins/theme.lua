---@param colors table<string, string>
local function recolor(colors)
  local options = require("catppuccin").options
  options.color_overrides.mocha = colors
  -- Private cache: instances recompile concurrently.
  options.compile_path = vim.fs.dirname(vim.fn.tempname())
  require("catppuccin.lib.compiler").compile("mocha")
  vim.cmd.colorscheme("catppuccin")
end


require("totalvim.lazy").add_specs({ {
  "catppuccin-nvim",
  event = "DeferredUIEnter",
  after = function()
    local palette = require("totalvim.palette")

    require("catppuccin").setup({
      flavour = "mocha",
      color_overrides = { mocha = palette.load() or {} },
      ---@param colors table<string, string>
      custom_highlights = function(colors)
        return {
          CursorLine = { bg = colors.surface1 },
          CursorLineNr = { fg = colors.lavender, style = { "bold" } },
          Visual = { bg = colors.selection },
          PmenuSel = { bg = colors.selection },
        }
      end,
      integrations = {
        blink_cmp = true,
        noice = true,
        cmp = false,
        which_key = true,
        gitsigns = true,
        treesitter = true,
        flash = true,
        mason = false,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    })

    vim.cmd.colorscheme("catppuccin")
    palette.watch(recolor)
  end,
}, })
