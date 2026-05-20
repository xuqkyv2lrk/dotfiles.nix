{
  description = "NixOS system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Pinned to the last nixpkgs commit before kernel 7.0.5 → 7.0.8, which
    # introduced a regression in NVIDIA DRM suspend/resume on niri.
    nixpkgs-kernel.url = "github:nixos/nixpkgs/da5ad661ba4e5ef59ba743f0d112cbc30e474f32";

    # Pinned to nixpkgs at Firefox 150.0.2, before the 150.0.3 Wayland popup
    # regression where context menus break after monitor reconnect on wake.
    nixpkgs-firefox.url = "github:nixos/nixpkgs/92a67e0f99c5ea44bfc26c07ebcfc26dbc129732";

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
      firefox = (import inputs.nixpkgs-firefox {
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
