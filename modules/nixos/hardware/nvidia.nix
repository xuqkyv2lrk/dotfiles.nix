{ pkgs, ... }:
{
  # Discrete NVIDIA GPU — primary display adapter (no Optimus/Prime).
  # For hybrid Optimus setups see thinkpad-t480s.nix.

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    # package defaults to config.boot.kernelPackages.nvidiaPackages.stable
  };

  boot.extraModprobeConfig = ''
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';

  programs.gamescope.enable = true;

  environment.systemPackages = with pkgs; [ libva-utils ];

  environment.variables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    DISABLE_WAYLAND = "0";
    ENABLE_GAMESCOPE_WSI = "1";
  };
}
