{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    arc-theme
    gnomeExtensions.alphabetical-app-grid
    gnomeExtensions.just-perfection
    gnomeExtensions.user-themes
    nautilus
  ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      accent-color = "purple";
      clock-show-date = true;
      clock-show-seconds = false;
      clock-show-weekday = true;
      color-scheme = "prefer-dark";
      cursor-theme = "Adwaita";
      document-font-name = "Cantarell 11";
      enable-animations = true;
      font-antialiasing = "grayscale";
      font-hinting = "slight";
      font-name = "Cantarell 11";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      monospace-font-name = "JetBrainsMonoNL Nerd Font Propo 10";
      show-battery-percentage = true;
      text-scaling-factor = 1.0;
    };

    "org/gnome/desktop/input-sources" = {
      sources = [ (lib.hm.gvariant.mkTuple [ "xkb" "us" ]) ];
      xkb-options = [ "terminate:ctrl_alt_bksp" "lv3:ralt_switch" ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      switch-to-workspace-1  = [ "<Super>1" ];
      switch-to-workspace-2  = [ "<Super>2" ];
      switch-to-workspace-3  = [ "<Super>3" ];
      switch-to-workspace-4  = [ "<Super>4" ];
      switch-to-workspace-5  = [ "<Super>5" ];
      switch-to-workspace-6  = [ "<Super>6" ];
      switch-to-workspace-7  = [ "<Super>7" ];
      switch-to-workspace-8  = [ "<Super>8" ];
      switch-to-workspace-9  = [ "<Super>9" ];
      move-to-workspace-1    = [ "<Super><Shift>1" ];
      move-to-workspace-2    = [ "<Super><Shift>2" ];
      move-to-workspace-3    = [ "<Super><Shift>3" ];
      move-to-workspace-4    = [ "<Super><Shift>4" ];
      move-to-workspace-5    = [ "<Super><Shift>5" ];
      move-to-workspace-6    = [ "<Super><Shift>6" ];
      move-to-workspace-7    = [ "<Super><Shift>7" ];
      move-to-workspace-8    = [ "<Super><Shift>8" ];
      move-to-workspace-9    = [ "<Super><Shift>9" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      theme = "libadwaita";
      titlebar-font = "JetBrainsMono Nerd Font Bold 11";
    };

    # Free Super+1..9 from app-switching so workspace binds above take effect
    "org/gnome/shell/keybindings" = {
      switch-to-application-1 = [];
      switch-to-application-2 = [];
      switch-to-application-3 = [];
      switch-to-application-4 = [];
      switch-to-application-5 = [];
      switch-to-application-6 = [];
      switch-to-application-7 = [];
      switch-to-application-8 = [];
      switch-to-application-9 = [];
    };

    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };

    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "small";
    };

    "org/gnome/nautilus/list-view" = {
      use-tree-view = true;
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
      search-view = "list-view";
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = lib.hm.gvariant.mkTuple [ 1119 759 ];
      initial-size-file-chooser = lib.hm.gvariant.mkTuple [ 890 550 ];
      maximized = false;
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-schedule-automatic = false;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
      ];
      rotate-video-lock-static = [];
      www = [];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "foot";
      name = "Terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>o";
      command = "firefox";
      name = "Firefox";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      binding = "<Super>e";
      command = "nautilus";
      name = "Nautilus";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      binding = "Launch1";
      command = "rog-control-center";
      name = "ASUS Rog Control Center";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      binding = "Launch4";
      command = "asusctl profile -n";
      name = "ASUS Fan Profile";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
      binding = "Launch3";
      command = "asusctl led-mode -n";
      name = "ASUS Aura";
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-timeout = 3600;
    };

    "org/gnome/shell" = {
      enabled-extensions = [
        "AlphabeticalAppGrid@stuarthayhurst"
        "just-perfection-desktop@just-perfection"
        "user-theme@gnome-shell-extensions"
      ];
    };

    "org/gnome/shell/extensions/just-perfection" = {
      accessibility-menu = true;
      activities-button = true;
      activities-button-icon-monochrome = true;
      activities-button-label = true;
      alt-tab-window-preview-size = 0;
      app-menu = false;
      app-menu-icon = true;
      app-menu-label = false;
      background-menu = true;
      calendar = true;
      clock-menu = true;
      clock-menu-position = 0;
      controls-manager-spacing-size = 22;
      dash = false;
      dash-icon-size = 0;
      double-super-to-appgrid = false;
      events-button = true;
      gesture = false;
      hot-corner = true;
      keyboard-layout = true;
      notification-banner-position = 2;
      osd = true;
      osd-position = 0;
      panel = true;
      panel-arrow = true;
      panel-corner-size = 1;
      panel-in-overview = true;
      panel-notification-icon = true;
      panel-size = 0;
      power-icon = true;
      quick-settings = true;
      ripple-box = true;
      search = false;
      show-apps-button = true;
      startup-status = 0;
      switcher-popup-delay = true;
      theme = true;
      top-panel-position = 0;
      type-to-search = true;
      weather = true;
      window-demands-attention-focus = true;
      window-picker-icon = false;
      window-preview-caption = false;
      window-preview-close-button = false;
      workspace = false;
      workspace-background-corner-size = 15;
      workspace-popup = false;
      workspace-wrap-around = false;
      workspaces-in-app-grid = false;
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Arc-Dark";
    };
  };
}
