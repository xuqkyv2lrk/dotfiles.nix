# Replace with the actual configuration.nix from xiuhcoatl.
# After a fresh install, copy /etc/nixos/configuration.nix here and
# copy /etc/nixos/hardware-configuration.nix to hardware-configuration.nix.
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # btrfs maintenance — scrub monthly
  services.btrfs.autoScrub.enable = true;

  # zram swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  networking.hostName = "xiuhcoatl";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York"; # update to match your locale
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.lqnw3c = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # Allow unfree packages (e.g. nvidia drivers, vscode, etc.)
  nixpkgs.config.allowUnfree = true;

  # Enable flakes and the new nix CLI
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Garbage collect automatically
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  system.stateVersion = "25.05";
}
