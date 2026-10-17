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
}
