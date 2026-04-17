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

  # Polls playerctl every 5 s and toggles noctalia idle inhibitor while media plays
  systemd.user.services.noctalia-media-inhibit = {
    Unit = {
      Description = "Inhibit noctalia idle when media is playing";
    };
    Service = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "5";
      ExecStart = toString (pkgs.writeShellScript "noctalia-media-inhibit" ''
        qs_shell="$HOME/.dotfiles.di/quickshell/noctalia-shell"
        inhibited=false
        while true; do
          status="$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null || printf "Stopped")"
          if [[ "$status" == "Playing" ]] && [[ "$inhibited" == "false" ]]; then
            ${pkgs.noctalia-qs}/bin/quickshell ipc --any-display \
              -p "$qs_shell" call idleInhibitor enable 2>/dev/null || true
            inhibited=true
          elif [[ "$status" != "Playing" ]] && [[ "$inhibited" == "true" ]]; then
            ${pkgs.noctalia-qs}/bin/quickshell ipc --any-display \
              -p "$qs_shell" call idleInhibitor disable 2>/dev/null || true
            inhibited=false
          fi
          sleep 5
        done
      '');
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Noctalia user configuration and shell
  xdg.configFile."noctalia".source    = lnDi "quickshell/noctalia/.config/noctalia";
  xdg.configFile."quickshell".source  = lnDi "quickshell/noctalia-shell";
}
