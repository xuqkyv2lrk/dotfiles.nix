{ config, pkgs, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  # Niri ecosystem packages
  # The compositor itself is enabled at system level via programs.niri.enable
  home.packages = with pkgs; [
    swaylock
    brightnessctl
  ];

  # dotfiles.di niri symlinks
  xdg.configFile."niri".source    = lnDi "niri/niri/.config/niri";
  xdg.configFile."hypr".source    = lnDi "niri/hypr/.config/hypr";
  xdg.configFile."swaylock".source = lnDi "niri/swaylock/.config/swaylock";
  xdg.configFile."gtk-3.0".source = lnDi "niri/gtk-3.0/.config/gtk-3.0";
  xdg.configFile."gtk-4.0".source = lnDi "niri/gtk-4.0/.config/gtk-4.0";
}
