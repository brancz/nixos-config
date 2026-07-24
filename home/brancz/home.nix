# home/brancz/home.nix
#
# Desktop (brancz-desktop) home-manager config: the shared base plus everything
# GUI / Wayland / workstation-specific. Headless hosts import ./base.nix directly
# instead of this file.
{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
    ./ghostty.nix
    ./chromium.nix
  ];

  # Snapshot of HM's defaults at first install. Set once, never change —
  # it does NOT need to track your nixpkgs version. Per-host (not in base.nix).
  home.stateVersion = "26.05";

  # GUI + workstation-only packages. The shared CLI set lives in base.nix.
  home.packages = with pkgs; [
    wl-clipboard # wl-copy/wl-paste; neovim's "+ register needs this on Wayland
    spotify signal-desktop
    opencode # terminal AI coding agent
    cargo-flamegraph samply hotspot heaptrack # rust / perf profiling
    clang mold # referenced by the cargo config below
  ];

  # Global cargo config: clang + mold for faster linking. Workstation dev only.
  home.file.".cargo/config.toml".text = ''
    [target.x86_64-unknown-linux-gnu]
    linker = "clang"
    rustflags = ["-C", "link-arg=-fuse-ld=mold"]
  '';
}
