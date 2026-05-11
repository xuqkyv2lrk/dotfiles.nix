{ ... }:
{
  imports = [
    ./modules/base.nix
    ./modules/noctalia.nix
    ./modules/niri.nix
  ];

  home.username      = "chdxn";
  home.homeDirectory = "/home/chdxn";
  home.stateVersion  = "25.11";
}
