{ config, lib, pkgs, ... }:
let
  hmUsers = config.home-manager.users or {};
  hasNoctalia = builtins.any (name:
    builtins.any (p: (p.pname or p.name or "") == "noctalia-qs")
      (hmUsers.${name}.home.packages or [])
  ) (builtins.attrNames hmUsers);
in
{
  config = lib.mkIf hasNoctalia {
    # Lock screen before the system suspends.
    systemd.services.lock-before-suspend = {
      description = "Lock noctalia screen before suspend";
      before = [ "sleep.target" ];
      wantedBy = [ "sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "lock-before-suspend" ''
          user=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend \
            | ${pkgs.gawk}/bin/awk '{print $3}' \
            | ${pkgs.gnugrep}/bin/grep -v root \
            | ${pkgs.coreutils}/bin/head -1)
          uid=$(${pkgs.coreutils}/bin/id -u "$user")
          export XDG_RUNTIME_DIR=/run/user/$uid
          home=$(${pkgs.gawk}/bin/awk -F: -v u="$user" '$1==u{print $6}' /etc/passwd)
          ${pkgs.noctalia-qs}/bin/quickshell ipc --any-display \
            -p "$home/.dotfiles.di/quickshell/noctalia-shell" \
            call lockScreen lock
          sleep 1
        '';
        TimeoutSec = 15;
      };
    };

  };
}
