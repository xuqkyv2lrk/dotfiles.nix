{ ... }:
{
  # Disable IR camera — not functional on Linux and presents an unnecessary surface
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04f2", ATTRS{idProduct}=="b615", ATTR{authorized}="0"
  '';

  # T480s supports S3 deep sleep — requires BIOS: Config → Power → Sleep State = Linux
  boot.kernelParams = [ "mem_sleep_default=deep" ];

  # Intel UHD 620 + NVIDIA MX150 (Optimus hybrid graphics)
  # niri runs on Intel; NVIDIA available for offloaded workloads.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;       # required for Wayland
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = false;                    # MX150 (GP108M) requires proprietary driver
    nvidiaSettings = false;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;  # provides nvidia-offload wrapper
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
