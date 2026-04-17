{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/hardware/thinkpad-t480s.nix
    ../../modules/nixos/laptop.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.btrfs.autoScrub.enable = true;

  zramSwap = { enable = true; algorithm = "zstd"; };

  networking.hostName = "jorvik";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

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

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.acpilight.enable = true;

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

  users.users.bxxjs = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" "libvirtd" ];
    shell        = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [ vim git wget curl pciutils ];

  programs.zsh.enable = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store   = true;
  };

  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 7d";
  };

  systemd.services.lock-before-suspend = {
    description = "Lock noctalia screen before suspend";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "bxxjs";
      Environment = "XDG_RUNTIME_DIR=/run/user/1000";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.noctalia-qs}/bin/quickshell ipc --any-display -p /home/bxxjs/.dotfiles.di/quickshell/noctalia-shell call lockScreen lock && sleep 1'";
      TimeoutSec = 10;
    };
  };

  # First NixOS version installed on this machine — do not change.
  system.stateVersion = "25.11";
}
