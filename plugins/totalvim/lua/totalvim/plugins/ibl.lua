require("totalvim.lazy").add_specs({ {
  "indent-blankline.nvim",
  event = "DeferredUIEnter",
  after = function()
    local highlight = {
      "RainbowDelimiterRed",
      "RainbowDelimiterYellow",
      "RainbowDelimiterBlue",
      "RainbowDelimiterOrange",
      "RainbowDelimiterGreen",
      "RainbowDelimiterViolet",
      "RainbowDelimiterCyan",
    }

    require("ibl").setup({
      indent = { char = "\u{250A}" },
      scope = {
        enabled = true,
        show_start = true,
        show_end = true,
        highlight = highlight,
      },
    })

    local hooks = require("ibl.hooks")
    hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
  end,
}, })
