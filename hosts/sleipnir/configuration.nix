{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/hardware/asus-rog.nix
    ../../modules/nixos/audio.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.btrfs.autoScrub.enable = true;

  zramSwap = { enable = true; algorithm = "zstd"; };

  networking.hostName = "sleipnir";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  services.libinput.enable = true;
  services.printing.enable = true;
  services.openssh.enable = true;
  services.upower.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
  ];

  programs.niri.enable = true;

  virtualisation.docker    = { enable = true; enableOnBoot = true; };
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

  users.users.x0xgo = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" "libvirtd" "dialout" ];
    shell        = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [ vim git wget curl pciutils ];

  programs.zsh.enable = true;

  # First NixOS version installed on this machine — do not change.
  system.stateVersion = "25.11";
}
