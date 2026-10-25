{ pkgs, ... }:
{
  imports = [
    ./modules/base.nix
    ./modules/noctalia.nix
    ./modules/niri.nix
    ./modules/umbriel.nix
  ];

  home.username      = "x0xgo";
  home.homeDirectory = "/home/x0xgo";
  home.stateVersion  = "25.11";
}
