local helpers = require("totalvim.lsp.helpers")

require("totalvim.lazy").add_specs({
  {
    "crates.nvim",
    after = function()
      require("crates").setup({
        lsp = {
          enabled = true,
          on_attach = helpers.default,
          actions = true,
          completion = true,
          hover = true,
        },
      })
    end,
    ft = { "toml" },
  },
})


local settings = {
  ["rust-analyzer"] = {
    inlayHints = {
      typeHints = { enable = true },
      chainingHints = { enable = true },
      bindingModeHints = { enable = true },
      closureReturnTypeHints = { enable = "always" },
      lifetimeElisionHints = { enable = "always" },
      maxLength = 5,
      enable = true,
    },
    lens = { enable = true },
    checkOnSave = {
      command = "clippy",
      allFeatures = true,
    },
    -- Maximise completion coverage: index every feature (not just defaults, so
    -- feature-gated APIs like optional Bevy plugins autocomplete), all targets, run
    -- build scripts and proc-macros (required for derive-heavy crates like Bevy).
    cargo = {
      features = "all",
      allTargets = true,
      buildScripts = { enable = true },
    },
    procMacro = {
      enable = true,
      attributes = { enable = true },
    },
    completion = {
      fullFunctionSignatures = { enable = true },
      autoimport = { enable = true },
    },
  },
}


return {
  name = "rust_analyzer",
  on_attach = { helpers.default, helpers.format_on_save },
  settings = settings,
  -- rust-analyzer's lspconfig defaults probe `rustc` at start to locate the sysroot
  -- src. In a flake project the toolchain comes from direnv, which loads async after
  -- FileType — so autostart would race and crash with ENOENT. Defer enable until the
  -- direnv env is exported (rustc on PATH).
  defer_direnv = true,
}
