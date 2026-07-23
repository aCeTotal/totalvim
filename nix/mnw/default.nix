{
  pkgs,
  lib,
  inputs,
  ...
}: {
  enable = true;
  appName = "totalvim";
  aliases = ["vi" "vim"];
  desktopEntry = false;

  extraBinPath =
    builtins.attrValues {
      inherit
        (pkgs)
        clang-tools
        rust-analyzer
        vscode-langservers-extracted
        typescript-language-server
        emmet-ls
        lua-language-server
        taplo
        yaml-language-server
        stylua
        ripgrep
        git
        direnv
        cmake
        ninja
        bear
        cmake-language-server
        openocd
        stlink
        # Language servers: C# (Microsoft.CodeAnalysis.LanguageServer), Java (jdtls),
        # Nix (nixd). Compilers/SDKs still come from the project's flake via direnv.
        roslyn-ls
        jdt-language-server
        nixd
        # Formatters (Nix, Java) and the C# debug adapter.
        nixfmt-rfc-style
        google-java-format
        netcoredbg
        ;
      inherit (pkgs) prettier;
      inherit (pkgs) gcc-arm-embedded;
      inherit (pkgs) probe-rs-tools;
    }
    # codelldb ships inside the vscode-lldb extension; its `adapter` output exposes
    # the `codelldb` binary used as the DAP adapter for Rust/C/C++.
    ++ [pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter]
    ++ lib.optionals pkgs.stdenv.isLinux [pkgs.wl-clipboard pkgs.xclip];

  # jdtls loads its debug/test features as bundle jars. Their store paths are exported
  # as env vars so the Lua config can glob them at runtime (see lsp/clients/java.lua).
  wrapperArgs = [
    "--set"
    "TOTALVIM_JAVA_DEBUG_BUNDLE"
    "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server"
    "--set"
    "TOTALVIM_JAVA_TEST_BUNDLE"
    "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test/server"
  ];

  extraLuaPackages = ps: [ps.jsregexp];

  plugins.start =
    builtins.attrValues {
      inherit
        (pkgs.vimPlugins)
        direnv-vim
        lz-n
        which-key-nvim
        nvim-lspconfig
        SchemaStore-nvim
        blink-cmp
        luasnip
        friendly-snippets
        lualine-nvim
        noice-nvim
        nvim-notify
        nui-nvim
        nvim-web-devicons
        oil-nvim
        conform-nvim
        rainbow-delimiters-nvim
        promise-async
        diffview-nvim
        telescope-nvim
        telescope-ui-select-nvim
        telescope-fzf-native-nvim
        plenary-nvim
        vim-nix
        ;
      nvim-treesitter = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
    }
    ++ [
      inputs.self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.vimPlugins.totalvim
    ];

  plugins.opt = builtins.attrValues {
    inherit
      (pkgs.vimPlugins)
      catppuccin-nvim
      crates-nvim
      flash-nvim
      gitsigns-nvim
      indent-blankline-nvim
      lspsaga-nvim
      mini-pairs
      neogit
      nvim-dap-ui
      nvim-dap-virtual-text
      nvim-jdtls
      roslyn-nvim
      nvim-ufo
      nvim-surround
      trouble-nvim
      bigfile-nvim
      ;
  };
}
