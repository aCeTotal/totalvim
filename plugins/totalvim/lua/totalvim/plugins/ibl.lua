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
        -- start/end underlines force a re-render of the whole scope on every
        -- scope change, which stutters fast cursor movement in large files
        show_start = false,
        show_end = false,
        highlight = highlight,
      },
    })

    local hooks = require("ibl.hooks")
    hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
  end,
}, })
