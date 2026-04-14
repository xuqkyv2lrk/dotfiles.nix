{ config, pkgs, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  # Sway ecosystem packages
  # The compositor itself is enabled at system level via programs.sway.enable
  home.packages = with pkgs; [
    kanshi     # output management / autorandr equivalent
    swaysome   # workspace groups
    swaynag    # dialog bar (used by default sway exit bind)
    brightnessctl
  ];

  # dotfiles.di sway symlinks
  xdg.configFile."sway".source    = lnDi "sway/sway/.config/sway";
  xdg.configFile."kanshi".source  = lnDi "sway/kanshi/.config/kanshi";
  xdg.configFile."swaylock".source = lnDi "sway/swaylock/.config/swaylock";
  xdg.configFile."swaynag".source = lnDi "sway/swaynag/.config/swaynag";
  xdg.configFile."gtk-3.0".source = lnDi "sway/gtk-3.0/.config/gtk-3.0";
  xdg.configFile."gtk-4.0".source = lnDi "sway/gtk-4.0/.config/gtk-4.0";
}
