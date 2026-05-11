{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/hardware/nvidia.nix
  ];

  # Bootloader & Kernel
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # DRM device order for the 57" Samsung — swap card0/card1 if 7680x2160 doesn't appear
  environment.variables.WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";

  # Performance & Maintenance
  services.btrfs.autoScrub.enable = true;
  zramSwap = { enable = true; algorithm = "zstd"; };

  # Networking
  networking.hostName = "bifrost";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Input & Peripherals
  services.libinput.enable = true;
  services.printing.enable = true;
  services.openssh.enable = true;
  services.upower.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Graphics & Display
  programs.niri.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
  ];

  # Virtualisation
  virtualisation.docker = { enable = true; enableOnBoot = true; };
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

  # User Configuration
  users.users.chdxn = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "libvirtd" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [ 
    vim git wget curl pciutils 
    # Adding display utils to help debug the 57" panel
    wayland-utils 
    vulkan-tools
  ];

  programs.zsh.enable = true;

  # Nix Settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  system.stateVersion = "25.11";
}
