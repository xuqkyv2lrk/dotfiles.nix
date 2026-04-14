{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
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

  # Allow unfree packages (Broadcom WiFi, etc.)
  nixpkgs.config.allowUnfree = true;

  users.users.lqnw3c = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };

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
    options = "--delete-older-than 14d";
  };

  # First NixOS version installed on this machine — do not change.
  system.stateVersion = "25.11";
}
