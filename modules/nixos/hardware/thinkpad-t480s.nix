{ ... }:
{
  # Disable IR camera — not functional on Linux and presents an unnecessary surface
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04f2", ATTRS{idProduct}=="b615", ATTR{authorized}="0"
  '';

  # T480s supports S0ix (Modern Standby)
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];
}
