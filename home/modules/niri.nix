{ config, pkgs, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  # Niri ecosystem packages
  # The compositor itself is enabled at system level via programs.niri.enable
  home.packages = with pkgs; [
    # Launcher
    fuzzel

    # File manager
    nautilus

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

    # Portals (GTK only — GNOME portal conflicts with non-GNOME compositors)
    xdg-desktop-portal-gtk

    # Xwayland — managed by niri's built-in integration (niri 26.04+),
    # which handles sleep/resume without the crash-on-resume bug that the
    # standalone systemd service had. Must be in PATH for niri to find it.
    xwayland-satellite
  ];

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.catppuccin-cursors.mochaMauve;
    name = "catppuccin-mocha-mauve-cursors";
    size = 24;
  };

  # Workaround for a Firefox 150 Wayland bug where popup/context-menu surfaces
  # break after the display disconnects and reconnects (DPMS or wake from sleep).
  # Watches the niri event stream for the workspace output going None → Some,
  # which signals a display reconnect, then nudges the output scale to force
  # Firefox and Electron apps to re-initialise their popup surfaces.
  systemd.user.services.niri-output-watcher = {
    Unit = {
      Description = "Cycle niri output scale on reconnect to fix Firefox popups";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "3s";
      ExecStart = pkgs.writeShellScript "niri-output-watcher" ''
        STATE_FILE="''${XDG_RUNTIME_DIR}/niri-output-was-off"

        niri msg event-stream | while IFS= read -r line; do
          case "$line" in
            *"Workspaces changed:"*)
              if echo "$line" | grep -q "output: None"; then
                touch "$STATE_FILE"
              elif [[ -f "$STATE_FILE" ]] && echo "$line" | grep -q "output: Some"; then
                rm "$STATE_FILE"
                sleep 1
                niri msg output HDMI-A-1 scale 1.501
                sleep 0.3
                niri msg output HDMI-A-1 scale 1.5
              fi
              ;;
          esac
        done
      '';
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # dotfiles.di niri symlinks
  home.file."bin/start-niri".source     = lnDi "niri/bin/bin/start-niri";

  xdg.configFile."niri".source          = lnDi "niri/niri/.config/niri";
  xdg.configFile."hypr".source          = lnDi "niri/hypr/.config/hypr";
  xdg.configFile."swappy".source        = lnDi "niri/swappy/.config/swappy";
  xdg.configFile."mimeapps.list".source = lnDi "niri/xdg/.config/mimeapps.list";
  xdg.configFile."gtk-3.0".source       = lnDi "niri/gtk-3.0/.config/gtk-3.0";
  xdg.configFile."gtk-4.0".source       = lnDi "niri/gtk-4.0/.config/gtk-4.0";

}
