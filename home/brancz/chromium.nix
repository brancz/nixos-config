# home/brancz/chromium.nix
{ pkgs, ... }:

{
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;

    # Extensions are pinned by Chrome Web Store ID and force-installed via
    # policy — they auto-update from the store but the *set* is declarative.
    # Swap these examples for what you actually use (ID is in the store URL).
    extensions = [
      { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
    ];

    commandLineArgs = [
      "--ozone-platform-hint=auto" # native Wayland instead of XWayland
    ];
  };
}
