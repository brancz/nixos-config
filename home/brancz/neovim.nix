# home/brancz/neovim.nix
{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Plugins from nixpkgs: pinned by flake.lock, native deps prebuilt.
    # NO Mason — every LSP/formatter binary comes from extraPackages instead.
    plugins = with pkgs.vimPlugins; [
      rustaceanvim          # rust-analyzer integration done right
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
      telescope-nvim
      telescope-fzf-native-nvim # native ext prebuilt by nix — a pain otherwise
      plenary-nvim
      gitsigns-nvim
      conform-nvim
      lualine-nvim
      catppuccin-nvim
      markdown-preview-nvim # :MarkdownPreviewToggle -> live preview in browser
      (nvim-treesitter.withPlugins (p: [
        p.rust p.nix p.lua p.go p.c p.cpp p.toml p.yaml
        p.json p.markdown p.bash p.proto p.sql
      ]))
    ];

    # Binaries neovim needs on PATH. Global fallbacks — inside a project,
    # the devShell's rust-analyzer (matching the pinned toolchain) wins via direnv.
    extraPackages = with pkgs; [
      rust-analyzer
      nil                 # nix LSP
      lua-language-server
      gopls
      go                  # gopls shells out to `go env GOMOD` to find the project
                          # root -- without it, opening any .go file errors
      ripgrep fd          # telescope
      stylua
      nixfmt
      lldb                # DAP via rustaceanvim
    ];

    # HM owns ~/.config/nvim/init.lua (it generates the plugin bootstrap there),
    # so we can't point xdg.configFile."nvim" at the repo -- that collides and
    # the switch fails. Instead HM's init.lua just requires our module, which is
    # symlinked in below.
    initLua = ''
      require("brancz")
    '';
  };

  # Our actual config, as a lua module on nvim's runtimepath. Symlinked OUT of
  # the nix store, so edits to the file take effect on the next nvim start --
  # no rebuild loop while tweaking. Points at the live checkout of this repo.
  xdg.configFile."nvim/lua/brancz/init.lua".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/home/brancz/nvim/init.lua";
}
