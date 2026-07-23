local helpers = require("totalvim.lsp.helpers")

-- Java uses nvim-jdtls rather than the generic lspconfig loop: jdtls needs a unique
-- per-project data directory and is (re)started per buffer. The jdtls launcher is on
-- PATH via jdt-language-server; the JDK to run the server is bundled by that package,
-- while the project's JDK comes from its flake via direnv.

-- Debug/test features load as bundle jars. Their directories are exported as env vars
-- by the mnw wrapper (see nix/mnw/default.nix); glob them at runtime so version bumps
-- don't need config changes.
local function collect_bundles()
  local bundles = {}
  local debug_dir = vim.env.TOTALVIM_JAVA_DEBUG_BUNDLE
  if debug_dir then
    vim.list_extend(bundles, vim.fn.glob(debug_dir .. "/com.microsoft.java.debug.plugin-*.jar", true, true))
  end
  local test_dir = vim.env.TOTALVIM_JAVA_TEST_BUNDLE
  if test_dir then
    vim.list_extend(bundles, vim.fn.glob(test_dir .. "/*.jar", true, true))
  end
  return bundles
end

local function start_jdtls()
  local root = vim.fs.root(0, { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "settings.gradle" })
    or vim.fn.getcwd()
  -- One workspace dir per project, keyed by the project's directory name.
  local workspace = vim.fs.joinpath(vim.fn.stdpath("cache"), "jdtls-workspace", vim.fn.fnamemodify(root, ":p:h:t"))

  require("jdtls").start_or_attach({
    cmd = { "jdtls", "-data", workspace },
    root_dir = root,
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    on_attach = function(client, bufnr)
      helpers.default(client, bufnr)
      -- Wire nvim-dap main-class launch configs once the client is attached.
      pcall(function()
        require("jdtls").setup_dap({ hotcodereplace = "auto" })
        require("jdtls.dap").setup_dap_main_class_configs()
      end)
    end,
    init_options = { bundles = collect_bundles() },
  })
end

require("totalvim.lazy").add_specs({
  {
    "nvim-jdtls",
    ft = "java",
    after = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = start_jdtls,
      })
      -- Start for the buffer that triggered the load (start_or_attach is idempotent).
      start_jdtls()
    end,
  },
})

require("totalvim.health").register_lsp("jdtls", "jdtls", { "java" })

-- nvim-jdtls owns the client lifecycle; skip the generic lspconfig setup loop.
return {
  name = "jdtls",
  activate = function() return false end,
}
