{ ... }:
{
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  hardware.bluetooth.powerOnBoot = false;

  # Prefer S3 deep sleep; kernel falls back to s2idle if unavailable
  boot.kernelParams = [ "mem_sleep_default=deep" ];
}
