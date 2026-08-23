{ lib, ... }:
{
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  hardware.bluetooth.powerOnBoot = lib.mkDefault false;

  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  powerManagement.powerDownCommands = ''
    for hub in /sys/bus/usb/devices/usb*/power/wakeup; do
      echo enabled > "$hub"
    done
  '';

  powerManagement.resumeCommands = ''
    touch /tmp/niri_just_resumed
  '';
}
