{ pkgs, ... }:
{
  imports = [
    ./modules/base.nix
    ./modules/noctalia.nix
    ./modules/niri.nix
  ];

  # v5 (native, TOML config, `noctalia` binary) installed beside the v4 qs setup in
  # modules/noctalia.nix while we port settings; only one shell can run at a time
  home.packages = [ pkgs.noctalia ];

  home.username      = "x0xgo";
  home.homeDirectory = "/home/x0xgo";
  home.stateVersion  = "25.11";
}
