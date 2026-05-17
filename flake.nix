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

    s4rchiso-plymouth = {
      url = "github:SergioRibera/s4rchiso-plymouth-theme/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, dotfiles-bootstrap, silentsddm, s4rchiso-plymouth, ... }@inputs: {
    nixosConfigurations.xiuhcoatl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/xiuhcoatl/configuration.nix
        ./modules/nixos/noctalia.nix
        ./modules/nixos/sddm.nix
        ./modules/nixos/plymouth.nix
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
        ./hosts/jorvik/configuration.nix
        ./modules/nixos/noctalia.nix
        ./modules/nixos/sddm.nix
        ./modules/nixos/plymouth.nix
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
        ./hosts/bifrost/configuration.nix
        ./modules/nixos/sddm.nix
        ./modules/nixos/plymouth.nix
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
