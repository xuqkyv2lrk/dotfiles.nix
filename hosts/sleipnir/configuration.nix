{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/hardware/asus-rog.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/laptop.nix
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
  programs.river-classic.enable = false;
  programs.umbriel.enable = true;

  # Stable names for the GPUs: card numbers can change between boots, and the by-path names
  # contain colons, which WLR_DRM_DEVICES uses as its separator
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ENV{ID_PATH}=="pci-0000:03:00.0", SYMLINK+="dri/dgpu"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ENV{ID_PATH}=="pci-0000:07:00.0", SYMLINK+="dri/igpu"
  '';

  # Umbriel renders on the RX 6700S; the 680M drives both panels and only scans out the
  # copied frames. The first device listed is the renderer. niri stays on the 680M.
  systemd.user.services.umbriel.environment.WLR_DRM_DEVICES = "/dev/dri/dgpu:/dev/dri/igpu";

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
