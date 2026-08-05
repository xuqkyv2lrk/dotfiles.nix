{ pkgs, config, lib, ... }:
{
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.kernelParams = lib.mkDefault [ "usbcore.autosuspend=-1" ];
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

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/autosuspend", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2109", ATTR{idProduct}=="4817", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2109", ATTR{idProduct}=="3817", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1a40", ATTR{idProduct}=="0801", ATTR{power/control}="on"
  '';

  services.btrfs.autoScrub.enable = lib.mkDefault true;
  services.libinput.enable = lib.mkDefault true;
  services.openssh.enable = lib.mkDefault true;
  services.upower.enable = lib.mkDefault true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  services.mullvad-vpn.enable = true;

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

  programs.dconf.enable = lib.mkDefault true;
  programs.niri.enable = lib.mkDefault true;
  programs.river-classic.enable = lib.mkDefault true;
  programs.nix-ld.enable = true;
  programs.zsh.enable = lib.mkDefault true;

  nixpkgs.config.allowUnfree = lib.mkDefault true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  services.flatpak.enable = true;

  environment.sessionVariables.XDG_DATA_DIRS = [
    "/var/lib/flatpak/exports/share"
    "\${HOME}/.local/share/flatpak/exports/share"
  ];

  xdg.portal.config = {
    niri = {
      default = lib.mkForce [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gtk" ];
    };
    river = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
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
    glow
    koreader
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
