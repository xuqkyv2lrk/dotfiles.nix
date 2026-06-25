{ ... }:
{
  imports = [
    ./modules/base.nix
    ./modules/noctalia.nix
    ./modules/sway.nix
  ];

  home.username = "lqnw3c";
  home.homeDirectory = "/home/lqnw3c";

  # Set once at install time — do not change after initial activation.
  home.stateVersion = "25.05";
}
