{ config, pkgs, lib, ... }:
let
  cfg = config.custom.noctaliaLock;
  homeDir = config.users.users.${cfg.user}.home;
in
{
  options.custom.noctaliaLock = {
    enable = lib.mkEnableOption "lock noctalia screen before suspend";
    user = lib.mkOption {
      type = lib.types.str;
      description = "User to lock the screen for";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.lock-before-suspend = {
      description = "Lock noctalia screen before suspend";
      before = [ "sleep.target" ];
      wantedBy = [ "sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = pkgs.writeShellScript "lock-before-suspend" ''
          export XDG_RUNTIME_DIR=/run/user/$(id -u ${cfg.user})
          ${pkgs.noctalia-qs}/bin/quickshell ipc --any-display \
            -p ${homeDir}/.dotfiles.di/quickshell/noctalia-shell \
            call lockScreen lock
          sleep 1
        '';
        TimeoutSec = 15;
      };
    };
  };
}
