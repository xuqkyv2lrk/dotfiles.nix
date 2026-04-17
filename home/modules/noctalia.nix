{ config, pkgs, lib, ... }:
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

  # Lock noctalia before system suspend (lid close, manual suspend, etc.)
  systemd.user.services.lock-before-suspend = {
    Unit = {
      Description = "Lock noctalia screen before suspend";
      Before = [ "sleep.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe pkgs.noctalia-qs} ipc --any-display -p ${config.home.homeDirectory}/.dotfiles.di/quickshell/noctalia-shell call lockScreen lock";
      TimeoutSec = "10";
    };
    Install.WantedBy = [ "sleep.target" ];
  };

  # Noctalia user configuration and shell
  xdg.configFile."noctalia".source    = lnDi "quickshell/noctalia/.config/noctalia";
  xdg.configFile."quickshell".source  = lnDi "quickshell/noctalia-shell";
}
