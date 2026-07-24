# home/brancz/base.nix
#
# Shared, headless-safe home-manager config for the `brancz` user. Imported by
# this repo's desktop entry point (home.nix), and exposed as a flake output
# (homeModules.base) so it can be reused by other flakes.
#
# RULE: keep this module free of anything GUI / Wayland / workstation-specific
# (terminals, browsers, desktop apps, big dev toolchains). Those belong in
# home.nix. Anything here lands on every machine that imports it, including
# headless ones.
#
# Note: home.stateVersion is intentionally NOT set here -- it is install-specific,
# so each consuming host sets its own.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./zsh.nix
    ./tmux.nix
    ./neovim.nix
    ./gpg.nix
  ];

  # mkDefault so a host could override, though it's brancz everywhere.
  home.username = lib.mkDefault "brancz";
  home.homeDirectory = lib.mkDefault "/home/brancz";
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.home-manager.enable = true;

  # Core CLI, useful on every machine including headless servers. Project
  # toolchains do NOT go here -- they live in per-project flake devShells.
  home.packages = with pkgs; [
    ripgrep fd bat eza jq btop
    gh
    kubectl k9s kubectx

    # Carried over from the old dotfiles repo. Anything named git-* on PATH
    # becomes a `git <name>` subcommand, so this is `git recent`.
    (writeShellScriptBin "git-recent" ''
      # Branches you've most recently checked out, newest first, deduped.
      git reflog |
        grep -Eio "moving from ([^[:space:]]+)" |
        awk '{ print $3 }' |
        awk '!x[$0]++' |
        head -n 30
    '')
  ];

  programs.git = {
    enable = true;
    signing = {
      # Trailing "!" forces this exact subkey. Without it gpg only uses this to
      # locate the primary key, then picks the newest signing-capable subkey --
      # which is the [SA] auth subkey, not this [S] one.
      key = "0x98FBDB62D861054B!";
      signByDefault = true;
    };
    # userName/userEmail/extraConfig were folded into `settings` upstream.
    settings = {
      user.name = "Frederic Branczyk";
      user.email = "fbranczyk@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autosquash = true;
      push.autoSetupRemote = true;
    };
  };

  # The glue for per-project Rust flakes: cd into a repo -> devShell activates.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # caches shells, makes activation instant
  };

  programs.fzf.enable = true; # auto-wires zsh keybindings (C-r, C-t)
  programs.zoxide.enable = true;
}
