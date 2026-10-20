{ pkgs, ... }:
{
  services.asusd.enable = true;

  # Hybrid keeps the dGPU powered down until an app is offloaded to it;
  # the MUX (AsusMuxDgpu) keeps it active at all times and needs a reboot to change.
  services.supergfxd.enable = true;
  services.supergfxd.settings.mode = "Hybrid";

  services.power-profiles-daemon.enable = true;

  # asusd maps the power-profiles-daemon profile onto the ACPI platform_profile.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="AC0", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance"
    SUBSYSTEM=="power_supply", KERNEL=="AC0", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
  '';

  # The shared niri config pins rendering to renderD128, which is the dGPU here and
  # keeps it awake in Hybrid mode. Point the gitignored local.kdl at the boot_vga
  # device (the iGPU in Hybrid) via by-path, since renderD numbering can swap.
  home-manager.sharedModules = [
    ({ config, lib, ... }: {
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
