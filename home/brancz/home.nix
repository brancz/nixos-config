# home/brancz/home.nix
{ config, pkgs, ... }:

{
  imports = [
    ./zsh.nix
    ./tmux.nix
    ./neovim.nix
    ./ghostty.nix
    ./gpg.nix
    ./chromium.nix
  ];

  home.username = "brancz";
  home.homeDirectory = "/home/brancz";
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Snapshot of HM's defaults at first install. Set once, never change —
  # it does NOT need to track your nixpkgs version.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # User CLI tools. Project toolchains do NOT go here — they live in
  # per-project flake devShells activated by direnv.
  home.packages = with pkgs; [
    ripgrep fd bat eza jq btop
    gh
    wl-clipboard # wl-copy/wl-paste; neovim's "+ register needs this on Wayland
    kubectl k9s kubectx
    spotify signal-desktop
    opencode # terminal AI coding agent
    cargo-flamegraph samply hotspot heaptrack
    clang mold # referenced by the global cargo config below

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

  # Global cargo config, managed declaratively.
  home.file.".cargo/config.toml".text = ''
    [target.x86_64-unknown-linux-gnu]
    linker = "clang"
    rustflags = ["-C", "link-arg=-fuse-ld=mold"]
  '';
}
