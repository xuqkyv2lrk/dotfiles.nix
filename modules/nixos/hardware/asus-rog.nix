{ ... }:
{
  services.asusd.enable = true;

  # Hybrid keeps the dGPU powered down until an app is offloaded to it;
  # the MUX (AsusMuxDgpu) keeps it active at all times and needs a reboot to change.
  services.supergfxd.enable = true;
  services.supergfxd.settings.mode = "Hybrid";

  # asusd maps the power-profiles-daemon profile (enabled in laptop.nix) onto
  # the ACPI platform_profile.

  # The shared niri config pins rendering to renderD128, which is the dGPU here and
  # keeps it awake in Hybrid mode. Point the gitignored local.kdl at the boot_vga
  # device (the iGPU in Hybrid) via by-path, since renderD numbering can swap.
  home-manager.sharedModules = [
    ({ config, lib, pkgs, ... }: {
      # The app registers its tray icon once at startup, so wait for Noctalia's
      # StatusNotifierWatcher before launching it.
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

      home.activation.niriRenderOnIgpu = lib.hm.dag.entryAfter ["writeBoundary"] ''
        local_kdl="${config.home.homeDirectory}/.dotfiles.di/niri/niri/.config/niri/local.kdl"
        if [ -d "$(dirname "$local_kdl")" ] && ! grep -qs render-drm-device "$local_kdl"; then
          for dev in /sys/bus/pci/devices/*; do
            if [ "$(cat "$dev/boot_vga" 2>/dev/null)" = 1 ]; then
              printf '\ndebug {\n    render-drm-device "/dev/dri/by-path/pci-%s-render"\n}\n' \
                "$(basename "$dev")" | $DRY_RUN_CMD tee -a "$local_kdl" >/dev/null
              break
            fi
          done
        fi
      '';
    })
  ];
}
