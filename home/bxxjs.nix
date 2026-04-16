{ config, pkgs, ... }:
{
  imports = [
    ./modules/base.nix
    ./modules/noctalia.nix
    ./modules/niri.nix
  ];

  home.username      = "bxxjs";
  home.homeDirectory = "/home/bxxjs";
  home.stateVersion  = "25.11";
}
