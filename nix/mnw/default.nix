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
        cmake-language-server
        openocd
        stlink
        renode
        ;
      inherit (pkgs) prettier;
      inherit (pkgs) gcc-arm-embedded;
      inherit (pkgs) probe-rs-tools;
    }
    ++ lib.optionals pkgs.stdenv.isLinux [pkgs.wl-clipboard pkgs.xclip];

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
      nvim-ufo
      nvim-surround
      trouble-nvim
      bigfile-nvim
      ;
  };
}
