{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/audio.nix
  ];

  networking.hostName = "bifrost";

  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  # DRM device order for the 57" Samsung — swap card0/card1 if 7680x2160 doesn't appear
  environment.variables.WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";

  hardware.bluetooth.powerOnBoot = true;

  hardware.printers = {
    ensurePrinters = [{
      name = "Canon_iP8700";
      deviceUri = "ipp://192.168.22.80/ipp/print";
      model = "gutenprint.5.3://bjc-iP8700-series/expert";
      ppdOptions.PageSize = "Letter";
    }];
    ensureDefaultPrinter = "Canon_iP8700";
  };

  virtualisation.docker = { enable = true; enableOnBoot = true; };
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  users.users.chdxn = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "libvirtd" "dialout" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
    wayland-utils
    vulkan-tools
    iriun-webcam
  ];

  system.stateVersion = "25.11";
}
