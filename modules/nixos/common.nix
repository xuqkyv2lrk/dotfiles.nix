{ pkgs, config, lib, ... }:
{
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 video_nr=2 card_label="Iriun Webcam"
  '';

  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd";
  };

  networking.networkmanager.enable = lib.mkDefault true;

  time.timeZone = lib.mkDefault "America/New_York";

  services.btrfs.autoScrub.enable = lib.mkDefault true;
  services.libinput.enable = lib.mkDefault true;
  services.openssh.enable = lib.mkDefault true;
  services.upower.enable = lib.mkDefault true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint gutenprintBin cnijfilter2 cups-filters ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.bluetooth.enable = lib.mkDefault true;

  programs.niri.enable = lib.mkDefault true;
  programs.nix-ld.enable = true;
  programs.zsh.enable = lib.mkDefault true;

  nixpkgs.config.allowUnfree = lib.mkDefault true;

  xdg.portal.config = {
    niri = {
      default = lib.mkForce [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gtk" ];
    };
  };

  environment.systemPackages = with pkgs; [
    usbutils
    qt6.qtmultimedia
    vim
    git
    wget
    curl
    pciutils
  ];

  fonts.enableDefaultPackages = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    roboto
    cantarell-fonts
    liberation_ttf
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" ];
    serif     = [ "Noto Serif" ];
    monospace = [ "JetBrainsMono Nerd Font" ];
    emoji     = [ "Noto Color Emoji" ];
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];
  networking.firewall.allowedUDPPorts = [ 5000 ];
}
