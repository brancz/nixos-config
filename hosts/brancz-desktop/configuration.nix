# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Cap boot entries -- the ESP is a 1G vfat partition and every generation
  # writes one, so unbounded it eventually fills and breaks rebuilds.
  boot.loader.systemd-boot.configurationLimit = 20;

  boot.initrd.luks.devices."luks-c33915ba-1184-4331-b533-39d120d22327" = {
    device = "/dev/disk/by-uuid/c33915ba-1184-4331-b533-39d120d22327";
    allowDiscards = true; # let TRIM reach the SSD through LUKS (swap volume)
  };
  # allowDiscards for the root volume too (it's declared in hardware-configuration.nix,
  # which is generated and must not be edited; this attribute merges in).
  boot.initrd.luks.devices."luks-c5a84568-5e01-4ee3-9849-683d85ba6864".allowDiscards = true;

  # NB: do NOT add bypassWorkqueues here. It sets dm-crypt's no_read_workqueue /
  # no_write_workqueue, which is a *latency* tuning for low-queue-depth IO -- it does
  # crypto inline in the submitting thread instead of fanning it across a workqueue.
  # On this box (9950X, PCIe-5 NVMe) it TANKED high-QD parallel throughput ~5x
  # (12.6->2.6 GB/s seq, 1.34M->0.5M randread IOPS) because it serialised AES onto a
  # few threads. Raw-device speed was unaffected (14.6 GB/s), proving the flag was the
  # cause. The default workqueue behaviour wins for this workload; measured, reverted.
  networking.hostName = "brancz-desktop"; # Must match the flake attribute name.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Bluetooth. GNOME ships the pairing UI, so no blueman needed.
  # Left enabled so a USB bluetooth dongle works out of the box -- the onboard
  # radio does not (see the udev rule below).
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # The onboard MediaTek MT7927 bluetooth radio (usb 0489:e13a) is DEAD WEIGHT:
  # btusb binds it and requests mediatek/mt7927/BT_RAM_CODE_MT6639_2_1_hdr.bin,
  # which linux-firmware does not ship -- upstream WHENCE lists mt7927 as "Wireless
  # MACs" (wifi) only, with no BT blob published anywhere. The load fails with
  # -ENOENT, btusb resets the device and retries forever: one cold boot logged 178
  # resets in ~2 minutes.
  #
  # That reset storm is not harmless. The radio sits on usb bus 1, the same bus as
  # the keyboard (1-1.1.4.4), and the constant resets make the keyboard drop input.
  # (The mouse is on bus 7, which is why it kept working.)
  #
  # So: deauthorize the radio at udev time, which unbinds btusb and stops the loop.
  # Revisit if/when MediaTek publishes the bluetooth firmware.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0489", ATTR{idProduct}=="e13a", ATTR{authorized}="0"
  '';

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Open WebUI -- self-hosted LLM chat UI at http://localhost:8080.
  # Binds 127.0.0.1 by default (openFirewall stays false) so it is NOT exposed
  # on the network. Configure model backends (a local ollama, or a remote
  # OpenAI-compatible API + key) from inside the web UI's own settings.
  services.open-webui = {
    enable = true;
    environment = {
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
    };
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."brancz" = {
    isNormalUser = true;
    description = "Frederic Branczyk";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    shell = pkgs.zsh;
  };

  # REQUIRED even though zsh itself is configured in home-manager:
  # this registers zsh in /etc/shells and sets up /etc/zshenv so login works.
  programs.zsh.enable = true;

  # --- dev quality of life ----------------------------------------------------
  programs.nix-ld.enable = true;

  # --- YubiKey / GPG ------------------------------------------------------------
  services.pcscd.enable = true;                              # smartcard daemon
  services.udev.packages = [ pkgs.yubikey-personalization ]; # non-root card access
  programs.ssh.startAgent = false;  # gpg-agent IS the ssh-agent; avoid two agents
                                    # fighting over SSH_AUTH_SOCK
  # On GNOME also disable its ssh-agent, which hijacks SSH_AUTH_SOCK:
  # services.gnome.gcr-ssh-agent.enable = false;

  # Required for the NVIDIA driver (and google-chrome, etc.).
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "brancz" ];
    auto-optimise-store = true; # hardlink identical files in the store to save space
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Reclaim the store automatically -- on a box that rebuilds constantly it grows
  # unbounded otherwise.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Periodic TRIM for the NVMe SSD (paired with allowDiscards on the LUKS volumes).
  services.fstrim.enable = true;

  # Firmware/BIOS updates from Linux (fwupdmgr refresh && fwupdmgr update).
  services.fwupd.enable = true;

  # --- profiling / eBPF -------------------------------------------------------
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl = {
    "kernel.perf_event_paranoid" = -1;
    "kernel.kptr_restrict" = 0;
  };
  programs.bcc.enable = true;
  environment.systemPackages = with pkgs; [
    perf # top-level now; used to be config.boot.kernelPackages.perf
    bpftrace
    yubikey-manager # ykman
    git
    vim # root fallback editor
  ];

  # --- NVIDIA (Blackwell workstation card) -------------------------------------
  #hardware.graphics.enable = true;
  #services.xserver.videoDrivers = [ "nvidia" ];
  #hardware.nvidia = {
  #  open = true; # required for Blackwell
  #  package = config.boot.kernelPackages.nvidiaPackages.latest;
  #  modesetting.enable = true;
  #};

  # --- fonts (system-level so all apps see them) --------------------------------
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.symbols-only
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
