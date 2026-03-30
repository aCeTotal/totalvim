require("totalvim.lazy").add_specs({ {
  "indent-blankline.nvim",
  event = "DeferredUIEnter",
  after = function()
    require("ibl").setup({
      indent = { char = "\u{250A}" },
      scope = { enabled = true },
    })
  end,
}, })
