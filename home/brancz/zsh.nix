# home/brancz/zsh.nix
{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;

    # These come from nixpkgs, not OMZ — faster and pinned.
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 200000;
      save = 200000;
      extended = true;   # timestamps
      share = true;      # share across tmux panes
      ignoreDups = true;
      ignoreSpace = true;
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell"; # or whatever you use today
      plugins = [
        "git"
        "kubectl"
        "rust"
        "tmux"
      ];
    };

    shellAliases = {
      k = "kubectl";
      ls = "eza";
      ll = "eza -la";
      cat = "bat -p";
      g = "git";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos";
    };

    # Raw zshrc content for anything the module doesn't cover.
    # (This option was called initExtra before HM 25.05.)
    initContent = lib.mkMerge [
      # mkOrder 550 puts this ABOVE `source $ZSH/oh-my-zsh.sh`. The omz tmux
      # plugin reads these at source time, so setting them in the default
      # block (order 1000, which lands well below) would silently do nothing.
      (lib.mkOrder 550 ''
        # Autostart tmux, but only under ghostty -- not on the TTY console and
        # not over SSH, where an unexpected multiplexer is more annoying than
        # useful. The plugin already no-ops when we're inside tmux.
        if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
          ZSH_TMUX_AUTOSTART=true
          ZSH_TMUX_AUTOCONNECT=true  # attach to an existing session, don't pile up new ones
          ZSH_TMUX_AUTOQUIT=false    # detaching drops to a shell instead of closing the window
        fi
      '')

      ''
        setopt AUTO_PUSHD
        setopt PUSHD_IGNORE_DUPS

        # direnv is wired automatically by programs.direnv,
        # fzf by programs.fzf — nothing needed here for those.
      ''
    ];
  };
}
