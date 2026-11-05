{ pkgs, lib, ... }:
let
  # ES-DE and DuckStation are no longer in nixpkgs, so wrap the upstream AppImages
  es-de = pkgs.appimageTools.wrapType2 rec {
    pname = "es-de";
    version = "3.5.0";
    src = pkgs.fetchurl {
      url = "https://gitlab.com/es-de/emulationstation-de/-/package_files/357718352/download";
      name = "ES-DE_x64-${version}.AppImage";
      hash = "sha256-q8KZmhI4X4V3W9P5hvqJHHa2nfN5H3wS5MeDzzw2MPU=";
    };
  };

  duckstation = pkgs.appimageTools.wrapType2 rec {
    pname = "duckstation";
    version = "0.1-12083";
    src = pkgs.fetchurl {
      url = "https://github.com/stenzek/duckstation/releases/download/v${version}/DuckStation-x64.AppImage";
      hash = "sha256-xebwRfaiQggvyvqfAtVq2JXiM7lCcoeI0jKtDAx2XCQ=";
    };
  };

  retroarch = pkgs.retroarch.withCores (cores: with cores; [ snes9x mgba nestopia ]);

  # ES-DE in a fullscreen gamescope session; quitting ES-DE relaunches it, like Kodi on bragi
  couch-session = pkgs.writeShellScript "couch-session" ''
    exec ${pkgs.gamescope}/bin/gamescope -f -- ${pkgs.bash}/bin/bash -c \
      'while true; do ${es-de}/bin/es-de; sleep 1; done'
  '';

  # The RP6 exports its whole DuckStation user directory; only these parts are shared
  duckstation-stignore = pkgs.writeText "stignore" ''
    !/memcards
    !/savestates
    !/bios
    *
  '';

  user = "s1uyx";
  home = "/home/${user}";
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  zramSwap = { enable = true; algorithm = "zstd"; };

  networking.hostName = "idavoll";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  # amdgpu firmware for the 5700G's Vega iGPU, and AMD CPU microcode
  hardware.enableRedistributableFirmware = true;
  hardware.graphics = { enable = true; enable32Bit = true; };
  hardware.bluetooth = { enable = true; powerOnBoot = true; };
  # udev rules for Steam, Xbox, PlayStation and 8BitDo controllers
  hardware.steam-hardware.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${couch-session}";
      inherit user;
    };
  };

  # A console never sleeps on its own
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  services.tailscale.enable = true;

  services.syncthing = {
    enable = true;
    inherit user;
    dataDir = home;
    configDir = "${home}/.local/state/syncthing";
    openDefaultPorts = true;
    settings = {
      options.urAccepted = -1;
      devices.valhalla-hub = {
        id = "EVXONQU-3BGDCFM-EDTD3JA-DJIHZLM-WSK33FK-6C3PAJH-DCUUOP7-24BOSAL";
        addresses = [ "tcp://192.168.22.201:22000" "dynamic" ];
      };
      folders = {
        retroarch-saves = {
          label = "RetroArch";
          path = "${home}/.config/retroarch/saves";
          devices = [ "valhalla-hub" ];
        };
        ps2-memcards = {
          label = "NetherSX2 / PCSX2";
          path = "${home}/.config/PCSX2/memcards";
          devices = [ "valhalla-hub" ];
        };
        duckstation = {
          label = "DuckStation";
          path = "${home}/.local/share/duckstation";
          devices = [ "valhalla-hub" ];
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "L+ ${home}/.local/share/duckstation/.stignore - - - - ${duckstation-stignore}"
    # The shell is configured system-wide; an empty .zshrc stops zsh-newuser-install
    "f ${home}/.zshrc 0644 ${user} users -"
  ];

  nixpkgs.config.allowUnfree = true;

  users.users.${user} = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell        = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBlLgOdppXfl7Btvz4hx59JTp7ZNdPRklL+2eOlVOZMy"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    histSize = 10000;
    setOptions = [ "SHARE_HISTORY" "HIST_IGNORE_DUPS" "HIST_IGNORE_SPACE" ];
    # Catppuccin Mocha: blue user@host, mauve path, green prompt
    promptInit = ''
      PROMPT='%F{#89b4fa}%n@%m%f %F{#cba6f7}%~%f %F{#a6e3a1}❯%f '
    '';
    # Inputs are updated and pushed from the workstations, so these pull rather than
    # commit; idavoll has no push access or signing key
    shellAliases = {
      nrs = "git -C ${home}/.dotfiles.nix pull --ff-only && sudo nixos-rebuild switch --flake '${home}/.dotfiles.nix#idavoll'";
      nru = "git -C ${home}/.dotfiles.nix pull --ff-only && sudo nixos-rebuild boot --flake '${home}/.dotfiles.nix#idavoll'";
    };
  };

  environment.systemPackages = with pkgs; [
    es-de
    duckstation
    retroarch
    pcsx2
    vim
    git
    rsync
    pciutils
  ];

  # First NixOS version installed on this machine; do not change.
  system.stateVersion = "26.11";
}
