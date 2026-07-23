local helpers = require("totalvim.lsp.helpers")

return {
  name = "clangd",
  on_attach = { helpers.default },
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    -- Surface the whole API in completion: symbols from headers not yet #included are
    -- offered (with auto-import), and completion items carry full signatures. Needed so
    -- large APIs (e.g. Unreal Engine) are reachable without manually including headers.
    "--all-scopes-completion",
    "--completion-style=detailed",
    "--header-insertion-decorators",
    "--pch-storage=memory",
    -- Allow clangd to query nix devShell compilers (from `nix develop`/direnv) so it
    -- picks up every buildInput's -isystem include path, plus the ARM cross-compiler.
    "--query-driver=/nix/store/*/bin/cc,/nix/store/*/bin/c++,/nix/store/*/bin/*gcc,/nix/store/*/bin/*g++,/nix/store/*/bin/clang*,**/arm-none-eabi-*",
  },
}
