{ config, lib, pkgs, ... }:
let
  hmUsers = config.home-manager.users or {};
  hasNoctalia = builtins.any (name:
    builtins.any (p: (p.pname or p.name or "") == "noctalia-qs")
      (hmUsers.${name}.home.packages or [])
  ) (builtins.attrNames hmUsers);
in
{
  # After resume, NetworkManager reconnects but emits its StateChanged signal
  # before Quickshell's listener is ready — so the WiFi widget stays stale.
  # Waiting a few seconds then triggering a wifi rescan causes NM to re-emit
  # device state signals that Quickshell picks up without dropping the connection.
  config = lib.mkIf hasNoctalia {
    powerManagement.resumeCommands = ''
      { ${pkgs.coreutils}/bin/sleep 5; \
        ${pkgs.networkmanager}/bin/nmcli device wifi rescan 2>/dev/null || true; } &
    '';
  };
}
