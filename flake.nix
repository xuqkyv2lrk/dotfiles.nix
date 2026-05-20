{
  description = "NixOS system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Pinned nixpkgs used for two packages with regressions in the current
    # nixpkgs-unstable bump (nixpkgs rev d233902):
    #   - kernel: staying on 7.0.5 (linuxPackages_latest) while testing stability
    #   - firefox: 150.0.3 broke Wayland popup/context-menu surfaces after
    #     display reconnect (DPMS or wake); 150.0.2 from this rev is unaffected
    nixpkgs-kernel.url = "github:nixos/nixpkgs/da5ad661ba4e5ef59ba743f0d112cbc30e474f32";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles-bootstrap = {
      url = "gitlab:wd2nf8gqct/dotfiles.bootstrap";
      flake = false;
    };

    silentsddm = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, dotfiles-bootstrap, silentsddm, ... }@inputs:
  let
    overlay = final: prev: {
      ffmpeg-lh = final.callPackage ./pkgs/ffmpeg-lh.nix {};
      iriun-webcam = final.callPackage ./pkgs/iriun-webcam.nix {};
      # Pin to pre-upgrade nixpkgs (da5ad66) which has Firefox 150.0.2,
      # before the 150.0.3 Wayland popup regression. Reuses nixpkgs-kernel
      # input since it points to the same commit.
      firefox = (import inputs.nixpkgs-kernel {
        system = final.system;
        config.allowUnfree = true;
      }).firefox;
    };
  in {
    nixosConfigurations.xiuhcoatl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ overlay ]; }
        ./hosts/xiuhcoatl/configuration.nix
        ./modules/nixos/noctalia.nix
        ./modules/nixos/nix.nix
        ./modules/nixos/sddm.nix
        silentsddm.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.lqnw3c = import ./home/lqnw3c.nix;
        }
      ];
    };

    nixosConfigurations.jorvik = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ overlay ]; }
        ./hosts/jorvik/configuration.nix
        ./modules/nixos/noctalia.nix
        ./modules/nixos/nix.nix
        ./modules/nixos/sddm.nix
        silentsddm.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs   = true;
          home-manager.useUserPackages = true;
          home-manager.users.bxxjs = import ./home/bxxjs.nix;
        }
      ];
    };

    nixosConfigurations.bifrost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ overlay ]; }
        { boot.kernelPackages = (import inputs.nixpkgs-kernel {
            system = "x86_64-linux";
            config.allowUnfree = true;
          }).linuxPackages_latest; }
        ./hosts/bifrost/configuration.nix
        ./modules/nixos/common.nix
        ./modules/nixos/nix.nix
        ./modules/nixos/sddm.nix
        silentsddm.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs   = true;
          home-manager.useUserPackages = true;
          home-manager.users.chdxn = import ./home/chdxn.nix;
        }
      ];
    };

  };
}
