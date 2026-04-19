{ config, pkgs, lib, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  home.packages = with pkgs; [
    gnomeExtensions.paperwm
  ];

  xdg.configFile."paperwm/user.css".source = lnDi "gnome/_settings/paperwm-user.css";

  dconf.settings = {
    # Replaces the enabled-extensions list from gnome.nix with paperwm added
    "org/gnome/shell" = {
      enabled-extensions = lib.mkForce [
        "AlphabeticalAppGrid@stuarthayhurst"
        "just-perfection-desktop@just-perfection"
        "paperwm@paperwm.github.com"
        "user-theme@gnome-shell-extensions"
      ];
    };

    "org/gnome/shell/extensions/paperwm" = {
      disable-topbar-styling = true;
      show-window-position-bar = false;
      show-workspace-indicator = false;
      show-focus-mode-icon = false;
      show-open-position-icon = false;
      horizontal-margin = 8;
      vertical-margin = 2;
      vertical-margin-bottom = 2;
      window-gap = 8;
      selection-border-size = 2;
      selection-border-radius-top = 0;
      selection-border-radius-bottom = 0;
      animation-time = lib.hm.gvariant.mkDouble 0.15;
      cycle-width-steps = map lib.hm.gvariant.mkDouble [ 0.33333 0.5 0.66667 1.0 ];
      cycle-height-steps = map lib.hm.gvariant.mkDouble [ 0.33333 0.5 0.66667 1.0 ];
      minimap-scale = lib.hm.gvariant.mkDouble 0.0;
      minimap-shade-opacity = 255;
    };

    "org/gnome/shell/extensions/paperwm/keybindings" = {
      new-window                 = [ "<Super>Return" ];
      close-window               = [ "<Super>q" ];
      live-alt-tab               = [ "<Super>Tab" ];
      live-alt-tab-backward      = [ "<Super><Shift>Tab" ];
      switch-left                = [ "<Super>Left" ];
      switch-right               = [ "<Super>Right" ];
      switch-up                  = [ "<Super>Up" ];
      switch-down                = [ "<Super>Down" ];
      move-left                  = [ "<Super><Alt>Left" ];
      move-right                 = [ "<Super><Alt>Right" ];
      move-up                    = [ "<Super><Ctrl>Up" ];
      move-down                  = [ "<Super><Ctrl>Down" ];
      slurp-in                   = [ "<Super><Ctrl>Left" ];
      barf-out                   = [ "<Super><Ctrl>Right" ];
      barf-out-active            = [ "<Super><Ctrl><Shift>Right" ];
      cycle-width                = [ "<Super>r" ];
      cycle-width-backwards      = [ "<Super><Alt>r" ];
      cycle-height               = [ "<Super><Shift>r" ];
      toggle-maximize-width      = [ "<Super>f" ];
      paper-toggle-fullscreen    = [ "<Super><Shift>f" ];
      toggle-scratch             = [ "<Super>v" ];
      toggle-scratch-window      = [ "<Super>Escape" ];
      toggle-scratch-layer       = [ "<Super><Shift>Escape" ];
      switch-up-workspace        = [ "<Super>Page_Up" ];
      switch-down-workspace      = [ "<Super>Page_Down" ];
      move-up-workspace          = [ "<Super><Shift>Page_Up" ];
      move-down-workspace        = [ "<Super><Shift>Page_Down" ];
      switch-monitor-left        = [ "<Super><Shift>Left" ];
      switch-monitor-right       = [ "<Super><Shift>Right" ];
      switch-monitor-above       = [ "<Super><Shift>Up" ];
      switch-monitor-below       = [ "<Super><Shift>Down" ];
      move-monitor-left          = [ "<Super><Shift><Ctrl>Left" ];
      move-monitor-right         = [ "<Super><Shift><Ctrl>Right" ];
      move-monitor-above         = [ "<Super><Shift><Ctrl>Up" ];
      move-monitor-below         = [ "<Super><Shift><Ctrl>Down" ];
      swap-monitor-left          = [];
      swap-monitor-right         = [];
      swap-monitor-above         = [];
      swap-monitor-below         = [];
      center-horizontally        = [ "<Super>c" ];
      take-window                = [ "<Super>t" ];
      switch-focus-mode          = [ "<Super><Shift>e" ];
      toggle-top-and-position-bar = [ "<Super><Ctrl>b" ];
      switch-first               = [ "<Super>Home" ];
      switch-last                = [ "<Super>End" ];
      previous-workspace         = [ "<Super>Above_Tab" ];
      previous-workspace-backward = [ "<Super><Shift>Above_Tab" ];
    };
  };
}
