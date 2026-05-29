{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/hardware/thinkpad-t480s.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/virtualisation.nix
  ];

  networking.hostName = "jorvik";

  hardware.acpilight.enable = true;

  users.users.bxxjs = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" "libvirtd" "dialout" ];
    shell        = pkgs.zsh;
  };

  # First NixOS version installed on this machine — do not change.
  system.stateVersion = "25.11";
}
