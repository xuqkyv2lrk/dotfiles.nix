{ pkgs, config, lib, ... }:
{
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.kernelParams = lib.mkDefault [ "usbcore.autosuspend=-1" ];
  boot.kernelModules = [ "v4l2loopback" ];
  # The module's depmod index files collide with the kernel's own in the modules buildEnv on
  # kernel 7.3 (modules.alias), so drop them.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.v4l2loopback.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        find $out/lib/modules -maxdepth 2 -name 'modules.*' -delete
      '';
    }))
  ];
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
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
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

  # The auto-discovered driverless queue (implicitclass) feeds this printer blank
  # pages; the Gutenprint queue prints correctly. Model string tracks the nixpkgs
  # gutenprint version (check with `lpinfo -m | grep iP8700` if it stops matching).
  hardware.printers = {
    ensurePrinters = lib.mkDefault [{
      name = "Canon_iP8700_gp";
      deviceUri = "dnssd://Canon%20iP8700%20series._ipp._tcp.local/?uuid=00000000-0000-1000-8000-40F8DF2BC837";
      model = "gutenprint.5.3://bjc-iP8700-series/expert";
      ppdOptions.PageSize = "Letter";
    }];
    ensureDefaultPrinter = lib.mkDefault "Canon_iP8700_gp";
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
