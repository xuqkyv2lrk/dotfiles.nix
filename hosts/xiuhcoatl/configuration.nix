{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/hardware/dell-xps-13-9350.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/noctalia-lock.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # btrfs maintenance
  services.btrfs.autoScrub.enable = true;

  # zram swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # Network
  networking.hostName = "xiuhcoatl";
  networking.networkmanager.enable = true;

  # Locale
  time.timeZone = "America/New_York";

  # Sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.libinput.enable = true;
  services.printing.enable = true;
  services.openssh.enable = true;
  services.upower.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
  ];

  # Virtualisation
  # Desktop environment
  programs.niri.enable = true;

  xdg.portal.config = {
    niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gtk" ];
    };
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Allow unfree packages (Broadcom WiFi, 1password, etc.)
  nixpkgs.config.allowUnfree = true;

  users.users.lqnw3c = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "libvirtd" ];
    shell = pkgs.zsh;
  };

  # Bootstrap packages available before home-manager activates
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    pciutils
  ];

  programs.zsh.enable = true;

  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  custom.noctaliaLock = true;

  # First NixOS version installed on this machine — do not change.
  system.stateVersion = "25.11";
}
