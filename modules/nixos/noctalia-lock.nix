{ config, pkgs, lib, ... }:
{
  options.custom.noctaliaLock = lib.mkEnableOption "lock noctalia screen before suspend";

  config = lib.mkIf config.custom.noctaliaLock {
    systemd.services.lock-before-suspend = {
      description = "Lock noctalia screen before suspend";
      before = [ "sleep.target" ];
      wantedBy = [ "sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "lock-before-suspend" ''
          user=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend \
            | awk '{print $3}' | grep -v root | head -1)
          uid=$(id -u "$user")
          export XDG_RUNTIME_DIR=/run/user/$uid
          home=$(${pkgs.coreutils}/bin/getent passwd "$user" | cut -d: -f6)
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
