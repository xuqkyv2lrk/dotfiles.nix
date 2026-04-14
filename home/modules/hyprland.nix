{ config, pkgs, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  # Hyprland ecosystem packages
  # The compositor itself is enabled at system level via programs.hyprland.enable
  home.packages = with pkgs; [
    hypridle
    hyprpicker
    xdg-desktop-portal-hyprland
    socat   # used by monitor_hotplug.sh
  ];

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.catppuccin-cursors.mochaMauve;
    name = "catppuccin-mocha-mauve-cursors";
    size = 24;
  };

  # dotfiles.di hyprland symlinks
  home.file."bin/start-hypr".source = lnDi "hyprland/bin/bin/start-hypr";
  xdg.configFile."hypr".source      = lnDi "hyprland/hypr/.config/hypr";
  xdg.configFile."qt5ct".source   = lnDi "hyprland/qt5ct/.config/qt5ct";
  xdg.configFile."kvantum".source = lnDi "hyprland/kvantum/.config/kvantum";
  xdg.configFile."gtk-2.0".source = lnDi "hyprland/gtk-2.0/.config/gtk-2.0";
  xdg.configFile."gtk-3.0".source = lnDi "hyprland/gtk-3.0/.config/gtk-3.0";
  xdg.configFile."gtk-4.0".source = lnDi "hyprland/gtk-4.0/.config/gtk-4.0";
}
