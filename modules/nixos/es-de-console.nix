{ config, lib, pkgs, ... }:
let
  cfg = config.services.esde-console;
  home = config.users.users.${cfg.user}.home;

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

  themeSettings = {
    Theme = cfg.theme.name;
    ThemeColorScheme = cfg.theme.colorScheme;
    ThemeVariant = cfg.theme.variant;
    ThemeFontSize = cfg.theme.fontSize;
    ThemeAspectRatio = cfg.theme.aspectRatio;
    ThemeTransitions = cfg.theme.transitions;
  };

  pinnedSettings = themeSettings // cfg.settings;

  # es_settings.xml types each entry: <bool .../> for true/false, <string .../> otherwise
  setKeyLine = k: v:
    if builtins.isBool v
    then "set_key bool ${k} ${lib.boolToString v}"
    else "set_key string ${k} ${lib.escapeShellArg v}";

  # ES-DE rewrites es_settings.xml itself, so only the pinned keys are set, and only while
  # ES-DE is not running: anything else changed in its menus persists
  apply-settings = pkgs.writeShellScript "esde-apply-settings" ''
    settings="${home}/ES-DE/settings/es_settings.xml"
    mkdir -p "$(dirname "$settings")"
    [ -s "$settings" ] || printf '<?xml version="1.0"?>\n' > "$settings"
    set_key() {
      if ${pkgs.gnugrep}/bin/grep -q "<$1 name=\"$2\" " "$settings"; then
        ${pkgs.gnused}/bin/sed -i "s|<$1 name=\"$2\" value=\"[^\"]*\" />|<$1 name=\"$2\" value=\"$3\" />|" "$settings"
      else
        printf '<%s name="%s" value="%s" />\n' "$1" "$2" "$3" >> "$settings"
      fi
    }
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList setKeyLine pinnedSettings)}
  '';

  # Fullscreen gamescope session; quitting ES-DE relaunches it, like Kodi on bragi
  couch-session = pkgs.writeShellScript "couch-session" ''
    exec ${pkgs.gamescope}/bin/gamescope -f -- ${pkgs.bash}/bin/bash -c \
      'while true; do ${apply-settings}; ${es-de}/bin/es-de; sleep 1; done'
  '';

  # The RP6 exports its whole DuckStation user directory; only these parts are shared
  duckstation-stignore = pkgs.writeText "stignore" ''
    !/memcards
    !/savestates
    !/bios
    *
  '';
in
{
  options.services.esde-console = {
    enable = lib.mkEnableOption "an ES-DE console that boots straight into its frontend";

    user = lib.mkOption {
      type = lib.types.str;
      description = "Account that autologins into the ES-DE session and owns the saves.";
    };

    theme = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "art-book-next-es-de";
      };
      src = lib.mkOption {
        type = lib.types.package;
        description = "Theme directory, linked read-only into ~/ES-DE/themes.";
        default = pkgs.fetchFromGitHub {
          owner = "anthonycaccese";
          repo = "art-book-next-es-de";
          rev = "d772d07109701d9bd7c9fda305bfef6601105ab8";
          hash = "sha256-9yfLa1g5t2+bH4qyYQv2zX5QA/X5t0Jhs9gQ4J8jrlk=";
        };
      };
      colorScheme = lib.mkOption { type = lib.types.str; default = "oled-noir"; };
      variant = lib.mkOption { type = lib.types.str; default = "gamelist-list-metadata-miximage"; };
      fontSize = lib.mkOption { type = lib.types.str; default = "small"; };
      aspectRatio = lib.mkOption { type = lib.types.str; default = "automatic"; };
      transitions = lib.mkOption { type = lib.types.str; default = "automatic"; };
    };

    settings = lib.mkOption {
      type = with lib.types; attrsOf (either bool str);
      description = "Extra es_settings.xml keys pinned before each ES-DE start.";
      # A wired console has no battery or modem, and the network icons are noise on a TV
      default = {
        SystemStatusBluetooth = false;
        SystemStatusWifi = false;
        SystemStatusCellular = false;
        SystemStatusBattery = false;
      };
    };

    saveSync.hub = {
      id = lib.mkOption {
        type = lib.types.str;
        description = "Syncthing device ID of the always-on hub.";
      };
      address = lib.mkOption {
        type = lib.types.str;
        default = "dynamic";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # amdgpu and other GPU firmware, plus CPU microcode
    hardware.enableRedistributableFirmware = lib.mkDefault true;
    hardware.graphics = { enable = true; enable32Bit = true; };
    # udev rules for Steam, Xbox, PlayStation and 8BitDo controllers
    hardware.steam-hardware.enable = true;
    hardware.bluetooth = { enable = lib.mkDefault true; powerOnBoot = lib.mkDefault true; };

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
        inherit (cfg) user;
      };
    };

    # A console never sleeps on its own
    systemd.targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };

    services.syncthing = {
      enable = true;
      inherit (cfg) user;
      dataDir = home;
      configDir = "${home}/.local/state/syncthing";
      openDefaultPorts = true;
      settings = {
        options.urAccepted = -1;
        devices.valhalla-hub = {
          inherit (cfg.saveSync.hub) id;
          addresses = [ cfg.saveSync.hub.address "dynamic" ];
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
          # BIOS files stay out of git and the Nix store; every console gets them from the hub
          bios = {
            label = "BIOS";
            path = "${home}/Emulation/bios";
            devices = [ "valhalla-hub" ];
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      # Declared with the user as owner: tmpfiles would otherwise create link parents as
      # root, and Syncthing could not create ~/.local/state
      "d ${home}/.local 0755 ${cfg.user} users -"
      "d ${home}/.local/share 0755 ${cfg.user} users -"
      "d ${home}/.local/state 0755 ${cfg.user} users -"
      "d ${home}/.local/share/duckstation 0755 ${cfg.user} users -"
      "L+ ${home}/.local/share/duckstation/.stignore - - - - ${duckstation-stignore}"
      "d ${home}/ES-DE 0755 ${cfg.user} users -"
      "d ${home}/ES-DE/themes 0755 ${cfg.user} users -"
      "L+ ${home}/ES-DE/themes/${cfg.theme.name} - - - - ${cfg.theme.src}"
      "d ${home}/Emulation 0755 ${cfg.user} users -"
      "d ${home}/Emulation/bios 0755 ${cfg.user} users -"
      "d ${home}/.config 0755 ${cfg.user} users -"
      "d ${home}/.config/retroarch 0755 ${cfg.user} users -"
      "d ${home}/.config/PCSX2 0755 ${cfg.user} users -"
      # Each emulator reads its BIOS from the one synced folder
      "L+ ${home}/.config/retroarch/system - - - - ${home}/Emulation/bios"
      "L+ ${home}/.config/PCSX2/bios - - - - ${home}/Emulation/bios"
    ];

    environment.systemPackages = [ es-de duckstation retroarch pkgs.pcsx2 ];
  };
}
