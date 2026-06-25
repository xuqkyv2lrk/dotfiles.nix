{ config, pkgs, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  # River ecosystem packages
  # The compositor itself is enabled at system level via programs.river.enable
  home.packages = with pkgs; [
    catppuccin-gtk
    dart-sass
    gnome-keyring
    gnome-themes-extra
    gtk-engine-murrine
    kanshi
    nautilus
    papirus-icon-theme
    pwvucontrol
    sassc
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr
  ];

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.catppuccin-cursors.mochaMauve;
    name = "catppuccin-mocha-mauve-cursors";
    size = 24;
  };

  # dotfiles.di river symlinks
  home.file."bin/start-river".source = lnDi "river/bin/bin/start-river";

  xdg.configFile."river".source   = lnDi "river/river/.config/river";
  xdg.configFile."kanshi".source  = lnDi "river/kanshi/.config/kanshi";
  xdg.configFile."gtk-3.0".source = lnDi "river/gtk-3.0/.config/gtk-3.0";
  xdg.configFile."gtk-4.0".source = lnDi "river/gtk-4.0/.config/gtk-4.0";
}
