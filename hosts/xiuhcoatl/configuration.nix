{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/hardware/dell-xps-13-9350.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/noctalia-lock.nix
    ../../modules/nixos/virtualisation.nix
  ];

  networking.hostName = "xiuhcoatl";

  custom.noctaliaLock = true;

  users.users.lqnw3c = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "libvirtd" "dialout" ];
    shell = pkgs.zsh;
  };

  # First NixOS version installed on this machine — do not change.
  system.stateVersion = "25.11";
}
