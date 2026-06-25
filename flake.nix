{
  description = "NixOS system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
      ffmpeg-lh         = final.callPackage ./pkgs/ffmpeg-lh.nix {};
      iriun-webcam      = final.callPackage ./pkgs/iriun-webcam.nix {};
      river-tag-watcher = final.callPackage ./pkgs/river-tag-watcher {};
    };
  in {
    nixosConfigurations.xiuhcoatl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ overlay ]; }
        ./hosts/xiuhcoatl/configuration.nix
        ./modules/nixos/common.nix
        ./modules/nixos/nix.nix
        ./modules/nixos/sddm.nix
        ./modules/nixos/noctalia.nix
        silentsddm.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs        = true;
          home-manager.useUserPackages      = true;
          home-manager.backupFileExtension  = "backup";
          home-manager.users.lqnw3c        = import ./home/lqnw3c.nix;
        }
      ];
    };

    nixosConfigurations.jorvik = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ overlay ]; }
        ./hosts/jorvik/configuration.nix
        ./modules/nixos/common.nix
        ./modules/nixos/nix.nix
        ./modules/nixos/sddm.nix
        ./modules/nixos/noctalia.nix
        silentsddm.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs       = true;
          home-manager.useUserPackages     = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.bxxjs        = import ./home/bxxjs.nix;
        }
      ];
    };

    nixosConfigurations.bifrost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ overlay ]; }
        ./hosts/bifrost/configuration.nix
        ./modules/nixos/common.nix
        ./modules/nixos/nix.nix
        ./modules/nixos/sddm.nix
        ./modules/nixos/noctalia.nix
        silentsddm.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs       = true;
          home-manager.useUserPackages     = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.chdxn        = import ./home/chdxn.nix;
        }
      ];
    };


    nixosConfigurations.sleipnir = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ overlay ]; }
        ./hosts/sleipnir/configuration.nix
        ./modules/nixos/common.nix
        ./modules/nixos/nix.nix
        ./modules/nixos/sddm.nix
        ./modules/nixos/noctalia.nix
        silentsddm.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs   = true;
          home-manager.useUserPackages = true;
          home-manager.users.x0xgo = import ./home/x0xgo.nix;
        }
      ];
    };

  };
}
