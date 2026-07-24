{
  description = "Frederic's machines";

  inputs = {
    # Unstable is the right call for a desktop (fresh ghostty/neovim/nvidia).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Rust toolchains (oxalica/rust-overlay) are pinned per-project in each
    # project's own flake devShell, not system-wide -- so no rust input here.
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    # Attribute name must match networking.hostName -- nixos-rebuild defaults to
    # looking up the current hostname, so this lets `--flake ~/nixos` work bare.
    nixosConfigurations.brancz-desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/brancz-desktop/configuration.nix

        # home-manager as a NixOS module: one `nixos-rebuild switch`
        # updates system + user environment atomically.
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
	  home-manager.users.brancz = import ./home/brancz/home.nix;
          # If HM would clobber an existing dotfile, it refuses to switch.
          # This moves the old file aside instead of failing.
          home-manager.backupFileExtension = "hm-backup";
        }
      ];
    };

    # Reusable, headless-safe home-manager module. Exposed as a flake output so
    # other flakes can import it (`inputs.<this>.homeModules.base`) and share the
    # shell / editor / git / gpg config without duplicating it.
    homeModules.base = import ./home/brancz/base.nix;
  };
}
