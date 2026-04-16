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
  };

  outputs = { self, nixpkgs, home-manager, dotfiles-bootstrap, ... }@inputs: {
    nixosConfigurations.xiuhcoatl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/xiuhcoatl/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.lqnw3c = import ./home/lqnw3c.nix;
        }
      ];
    };
  };
}
