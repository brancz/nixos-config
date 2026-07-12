# home/brancz/gpg.nix
{ pkgs, ... }:

{
  programs.gpg = {
    enable = true;
    # pcscd (system service) owns the card reader; gpg's built-in CCID
    # driver would race it for the YubiKey otherwise.
    scdaemonSettings.disable-ccid = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;      # gpg-agent replaces ssh-agent entirely
    enableZshIntegration = true;  # exports GPG_TTY + SSH_AUTH_SOCK,
                                  # runs `updatestartuptty` for you

    # GUI pinentry. This matters with tmux: a tty pinentry pops on whichever
    # terminal last ran updatestartuptty, which is maddening across panes —
    # a GUI prompt sidesteps that entirely.
    pinentry.package = pkgs.pinentry-gnome3; # pinentry-qt on KDE

    defaultCacheTtl = 3600;
    defaultCacheTtlSsh = 3600;
    maxCacheTtl = 14400;
  };

  # Note: with keys on the YubiKey you do NOT need `sshKeys` / sshcontrol —
  # gpg-agent advertises on-card authentication keys to SSH automatically
  # once the card has been seen (`gpg --card-status`).
}
