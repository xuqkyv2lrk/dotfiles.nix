{ config, pkgs, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  # Noctalia (Quickshell-based shell layer) — shared across all WMs
  home.packages = with pkgs; [
    noctalia-qs

    # Media & audio controls invoked by Noctalia
    pamixer
    playerctl

    # Screenshot pipeline invoked by Noctalia
    grim
    slurp
    swappy

    # Clipboard manager
    cliphist

# System controls invoked by Noctalia
    brightnessctl
    wlsunset
  ];

  # Noctalia user configuration
  xdg.configFile."noctalia".source = lnDi "quickshell/noctalia/.config/noctalia";
}
