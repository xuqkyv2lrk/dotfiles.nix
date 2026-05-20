{ ... }:
{
  imports = [
    ./modules/base.nix
    ./modules/noctalia.nix
    ./modules/niri.nix
    ./modules/nvidia.nix
  ];

  home.username      = "chdxn";
  home.homeDirectory = "/home/chdxn";
  home.stateVersion  = "25.11";
}
