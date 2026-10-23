{ ... }:
{
  services.asusd.enable = true;

  # Hybrid keeps the dGPU powered down until an app is offloaded to it;
  # the MUX (AsusMuxDgpu) keeps it active at all times and needs a reboot to change.
  services.supergfxd.enable = true;
  services.supergfxd.settings.mode = "Hybrid";

  # asusd maps the power-profiles-daemon profile (enabled in laptop.nix) onto
  # the ACPI platform_profile.

  # The app registers its tray icon once at startup, so wait for Noctalia's
  # StatusNotifierWatcher before launching it.
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      systemd.user.services.rog-control-center = {
        Unit = {
          Description = "ROG Control Center (background, tray icon)";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in $(seq 30); do ${pkgs.systemd}/bin/busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1 && exit 0; sleep 1; done'";
          ExecStart = "/run/current-system/sw/bin/rog-control-center --background";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    })
  ];
}
