# home/brancz/ghostty.nix
{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    # Makes `infocmp xterm-ghostty` work everywhere locally:
    installBatSyntax = true;
    settings = {
      font-family = "JetBrains Mono";
      font-size = 11;
      # Ghostty's own theme name -- capitalized, space-separated (`ghostty
      # +list-themes`). NOT "catppuccin-mocha": that's the neovim colorscheme's
      # spelling, and ghostty errors out on it at startup.
      theme = "Catppuccin Mocha";
      window-decoration = true;
      # tmux is the multiplexer; keep ghostty itself simple
      confirm-close-surface = false;
      shell-integration = "zsh";
    };
  };

  # For SSH into other NixOS hosts, install the terminfo on THEM instead:
  #   environment.systemPackages = [ pkgs.ghostty.terminfo ];
}
