{ config, pkgs, lib, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  # Noctalia v5 — shared across all WMs
  home.packages = with pkgs; [
    noctalia

    # Seek keys in sway and the helper services below
    playerctl

    # Active-window screenshots in hyprland and sway, and region recording
    grim
    slurp
    swappy

    # Screen recording pipeline
    wf-recorder
    libnotify
    xdg-utils
    (pkgs.writeShellScriptBin "record-region" ''
      set -euo pipefail

      PID_FILE="''${XDG_RUNTIME_DIR:-/tmp}/wf-recorder.pid"
      OUT_FILE="''${XDG_RUNTIME_DIR:-/tmp}/wf-recorder.out"
      OUTPUT_DIR="$HOME/Videos/recordings"

      if [[ -f "$PID_FILE" ]]; then
        kill -SIGINT "$(cat "$PID_FILE")" 2>/dev/null || true
        rm -f "$PID_FILE"
        output="$(cat "$OUT_FILE")"
        rm -f "$OUT_FILE"
        (
          action="$(notify-send -t 4000 -i video-x-generic \
            --action="default=Open file" \
            "Recording saved" "$(basename "$output")")"
          [[ "$action" == "default" ]] && xdg-open "$output"
        ) &
      else
        region="$(${pkgs.slurp}/bin/slurp)" || exit 0
        mkdir -p "$OUTPUT_DIR"
        output="$OUTPUT_DIR/$(date +%Y-%m-%d_%H-%M-%S).webm"
        echo "$output" > "$OUT_FILE"
        ${pkgs.wf-recorder}/bin/wf-recorder \
          -g "$region" \
          -c libvpx-vp9 -p lossless=1 \
          -f "$output" &
        echo $! > "$PID_FILE"
        notify-send -t 4000 -i media-record "Recording started" "$region"
      fi
    '')

    brightnessctl
  ];

  # Polls playerctl every 5 s; enables noctalia DND while Plex is playing
  systemd.user.services.noctalia-plex-dnd = {
    Unit = {
      Description = "Enable noctalia DND while Plex is playing";
    };
    Service = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "5";
      ExecStart = toString (pkgs.writeShellScript "noctalia-plex-dnd" ''
        dnd_enabled=false
        while true; do
          status="$(${pkgs.playerctl}/bin/playerctl --player=%plex% status 2>/dev/null || printf "Stopped")"
          if [[ "$status" == "Playing" ]] && [[ "$dnd_enabled" == "false" ]]; then
            ${pkgs.noctalia}/bin/noctalia msg notification-dnd-set on 2>/dev/null || true
            dnd_enabled=true
          elif [[ "$status" != "Playing" ]] && [[ "$dnd_enabled" == "true" ]]; then
            ${pkgs.noctalia}/bin/noctalia msg notification-dnd-set off 2>/dev/null || true
            dnd_enabled=false
          fi
          sleep 5
        done
      '');
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

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
        inhibited=false
        while true; do
          status="$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null || printf "Stopped")"
          if [[ "$status" == "Playing" ]] && [[ "$inhibited" == "false" ]]; then
            ${pkgs.noctalia}/bin/noctalia msg caffeine-enable 2>/dev/null || true
            inhibited=true
          elif [[ "$status" != "Playing" ]] && [[ "$inhibited" == "true" ]]; then
            ${pkgs.noctalia}/bin/noctalia msg caffeine-disable 2>/dev/null || true
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

  # Re-centers the bar logo when the clock text width changes (day and month names). Mirrors the
  # unit files the bootstrap stows from dotfiles.di for non-nix machines.
  systemd.user.services.noctalia-center-logo = {
    Unit.Description = "Center the Noctalia bar logo";
    Service = {
      Type = "oneshot";
      Environment = [
        "PATH=${lib.makeBinPath (with pkgs; [ jq grim imagemagick noctalia niri coreutils gawk gnused ])}:/run/current-system/sw/bin"
      ];
      ExecStart = "%h/.local/bin/noctalia_center_logo.sh";
    };
  };

  systemd.user.timers.noctalia-center-logo = {
    Unit.Description = "Re-center the Noctalia bar logo";
    Timer = {
      OnActiveSec = 20;
      OnCalendar = "*-*-* *:00:30";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.file.".local/bin/noctalia_center_logo.sh".source =
    lnDi "noctalia/noctalia/.local/bin/noctalia_center_logo.sh";

  # Shadow the tracker3 D-Bus service file so nautilus doesn't block on a
  # 25-second activation timeout in non-GNOME sessions where tracker never runs.
  xdg.dataFile."dbus-1/services/org.freedesktop.Tracker3.Miner.Files.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.Tracker3.Miner.Files
    Exec=${pkgs.coreutils}/bin/false
  '';

  # Noctalia user configuration
  xdg.configFile."noctalia".source = lnDi "noctalia/noctalia/.config/noctalia";

  # Settings window changes: v5 saves them to the state file, which is linked into the repo so
  # every machine shares them.
  home.file.".local/state/noctalia/settings.toml".source =
    lnDi "noctalia/noctalia/.local/state/noctalia/settings.toml";
}
