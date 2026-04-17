{ config, pkgs, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  # Niri ecosystem packages
  # The compositor itself is enabled at system level via programs.niri.enable
  home.packages = with pkgs; [
    # Idle management
    hypridle

    # Launcher
    fuzzel

    # File manager
    nautilus

    # XWayland compatibility
    xwayland-satellite

    # Auth & secrets
    gnome-keyring
    polkit_gnome

    # Audio
    pwvucontrol

    # Theming
    gnome-themes-extra
    gtk-engine-murrine
    catppuccin-gtk
    papirus-icon-theme
    sassc
    dart-sass

    # NVIDIA VA-API
    libva-utils
    nvidia-vaapi-driver

    # Portals
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
  ];

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.catppuccin-cursors.mochaMauve;
    name = "catppuccin-mocha-mauve-cursors";
    size = 24;
  };

  # dotfiles.di niri symlinks
  home.file."bin/start-niri".source     = lnDi "niri/bin/bin/start-niri";

  systemd.user.services.idle = {
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "/usr/bin/env hypridle -c %h/.config/hypr/hypridle.conf";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  xdg.configFile."niri".source          = lnDi "niri/niri/.config/niri";
  xdg.configFile."hypr".source          = lnDi "niri/hypr/.config/hypr";
  xdg.configFile."swappy".source        = lnDi "niri/swappy/.config/swappy";
  xdg.configFile."mimeapps.list".source = lnDi "niri/xdg/.config/mimeapps.list";
  xdg.configFile."gtk-3.0".source       = lnDi "niri/gtk-3.0/.config/gtk-3.0";
  xdg.configFile."gtk-4.0".source       = lnDi "niri/gtk-4.0/.config/gtk-4.0";

}
