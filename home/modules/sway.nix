{ config, pkgs, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  # Sway ecosystem packages
  # The compositor itself is enabled at system level via programs.sway.enable
  home.packages = with pkgs; [
    catppuccin-gtk
    dart-sass
    gnome-keyring
    gnome-themes-extra
    gtk-engine-murrine
    kanshi          # output management / autorandr equivalent
    nautilus
    papirus-icon-theme
    pwvucontrol
    sassc
    swaysome        # workspace groups
    swaynag         # dialog bar (used by default sway exit bind)
    xdg-desktop-portal-gtk
  ];

  # dotfiles.di sway symlinks
  home.file."bin/start-sway".source = lnDi "sway/bin/bin/start-sway";

  xdg.configFile."hypr".source                               = lnDi "sway/hypr/.config/hypr";
  xdg.configFile."sway".source                               = lnDi "sway/sway/.config/sway";
  xdg.configFile."kanshi".source  = lnDi "sway/kanshi/.config/kanshi";
  xdg.configFile."swaylock".source = lnDi "sway/swaylock/.config/swaylock";
  xdg.configFile."swaynag".source = lnDi "sway/swaynag/.config/swaynag";
  xdg.configFile."gtk-3.0".source = lnDi "sway/gtk-3.0/.config/gtk-3.0";
  xdg.configFile."gtk-4.0".source = lnDi "sway/gtk-4.0/.config/gtk-4.0";
}
