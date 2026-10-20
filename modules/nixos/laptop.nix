{ lib, pkgs, ... }:
{
  services.power-profiles-daemon.enable = true;

  # performance on AC, power-saver on battery; matches any mains supply since the
  # AC node name differs per vendor (AC, AC0, ACAD, ADP1)
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
  '';

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  hardware.bluetooth.powerOnBoot = lib.mkDefault false;

  boot.kernelParams = [ "mem_sleep_default=deep" ];

  powerManagement.powerDownCommands = ''
    for hub in /sys/bus/usb/devices/usb*/power/wakeup; do
      echo enabled > "$hub"
    done
  '';

  powerManagement.resumeCommands = ''
    touch /tmp/niri_just_resumed
  '';
}
