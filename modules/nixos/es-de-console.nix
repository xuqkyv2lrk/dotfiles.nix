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

  # ES-DE is pinned by Nix too, so its update check only produces a nag
  pinnedSettings = themeSettings // { ApplicationUpdaterFrequency = "never"; } // cfg.settings;

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

  bios = "${home}/Emulation/bios";

  # SDL gamepad n as one PlayStation pad. SDL names buttons by position (A = bottom),
  # so this matches the PlayStation layout on Xbox-style pads like the 8BitDo.
  # DuckStation and PCSX2 share the binding syntax and most key names.
  sdlPad = n: {
    Up = "SDL-${toString n}/DPadUp";
    Down = "SDL-${toString n}/DPadDown";
    Left = "SDL-${toString n}/DPadLeft";
    Right = "SDL-${toString n}/DPadRight";
    Cross = "SDL-${toString n}/A";
    Circle = "SDL-${toString n}/B";
    Square = "SDL-${toString n}/X";
    Triangle = "SDL-${toString n}/Y";
    Select = "SDL-${toString n}/Back";
    Start = "SDL-${toString n}/Start";
    L1 = "SDL-${toString n}/LeftShoulder";
    R1 = "SDL-${toString n}/RightShoulder";
    L2 = "SDL-${toString n}/+LeftTrigger";
    R2 = "SDL-${toString n}/+RightTrigger";
    L3 = "SDL-${toString n}/LeftStick";
    R3 = "SDL-${toString n}/RightStick";
    LUp = "SDL-${toString n}/-LeftY";
    LDown = "SDL-${toString n}/+LeftY";
    LLeft = "SDL-${toString n}/-LeftX";
    LRight = "SDL-${toString n}/+LeftX";
    RUp = "SDL-${toString n}/-RightY";
    RDown = "SDL-${toString n}/+RightY";
    RLeft = "SDL-${toString n}/-RightX";
    RRight = "SDL-${toString n}/+RightX";
    SmallMotor = "SDL-${toString n}/SmallMotor";
    LargeMotor = "SDL-${toString n}/LargeMotor";
  };

  # Both emulators number pads 1A, 2A, 1B, 1C, 1D: Pad2 is the second console port for
  # ordinary 2-player games, Pad3-5 the multitap slots used when a game turns it on.
  # Player 2 sits on both 2A and 1B; only one of them is live at a time in practice.
  padSlots = type: {
    Pad1 = sdlPad 0 // { Type = type; };
    Pad2 = sdlPad 1 // { Type = type; };
    Pad3 = sdlPad 1 // { Type = type; };
    Pad4 = sdlPad 2 // { Type = type; };
    Pad5 = sdlPad 3 // { Type = type; };
  };

  # Select is the function key, mirroring the RP6's RetroArch hotkeys. The 8BitDo's
  # pair and profile buttons never reach the host, so only Home is free besides it.
  fn = button: "SDL-0/Back & SDL-0/${button}";
  pauseCombo = "SDL-0/Guide";
  fastForward = "2.0";
  quitCombo = fn "Start";

  # file -> section -> key -> value. Only these keys are pinned, so anything else
  # changed in an emulator's own menus persists. Without the wizard and fullscreen
  # keys, each emulator opens a first-run dialog hidden behind gamescope.
  emulatorSettings = {
    "${home}/.local/share/duckstation/settings.ini" = padSlots "AnalogController" // {
      Main = {
        SetupWizardIncomplete = "false";
        StartFullscreen = "true";
        ConfirmPowerOff = "false";
        # 0 means unlimited, far too fast to play through
        FastForwardSpeed = fastForward;
      };
      # Nix pins the version; an update prompt only stalls the launch
      AutoUpdater.CheckAtStartup = "false";
      BIOS = {
        SearchDirectory = bios;
        # Real console BIOSes play the white Sony intro and chime; the PSP-extracted
        # one has it stripped, so it only covers PAL where no real dump exists
        PathNTSCU = "scph5501.bin";
        PathNTSCJ = "scph5500.bin";
        PathPAL = "psxonpsp660.bin";
        # Full boot animation, white Sony screen included
        PatchFastBoot = "false";
        FastForwardBoot = "false";
      };
      # Sized for the 5700G's iGPU: 4x is about 1080p, and PGXP stops polygon wobble
      GPU = {
        Renderer = "Vulkan";
        ResolutionScale = "4";
        PGXPEnable = "true";
      };
      Hotkeys = {
        OpenPauseMenu = pauseCombo;
        PowerOff = quitCombo;
        SaveSelectedSaveState = fn "LeftShoulder";
        LoadSelectedSaveState = fn "+LeftTrigger";
        SelectNextSaveStateSlot = fn "DPadUp";
        SelectPreviousSaveStateSlot = fn "DPadDown";
        ToggleFastForward = fn "+RightTrigger";
        TogglePause = fn "B";
      };
    };
    "${home}/.config/PCSX2/inis/PCSX2.ini" = padSlots "DualShock2" // {
      UI = {
        # Without it PCSX2 treats the ini as corrupt and offers to reset it to defaults
        SettingsVersion = "1";
        SetupWizardIncomplete = "false";
        StartFullscreen = "true";
        ConfirmShutdown = "false";
        HideMouseCursor = "true";
      };
      Folders.Bios = bios;
      Filenames.BIOS = "SCPH-70012.bin";
      AutoUpdater.CheckAtStartup = "false";
      # PCSX2 skips the BIOS boot animation unless fast boot is off
      EmuCore = {
        EnableFastBoot = "false";
        # The pinned renderer and boot settings are deliberate; skip the on-screen nag
        WarnAboutUnsafeSettings = "false";
      };
      Framerate.TurboScalar = fastForward;
      # Renderer 14 is Vulkan; 2x is the safe ceiling for the iGPU in heavier games
      "EmuCore/GS" = {
        Renderer = "14";
        upscale_multiplier = "2";
      };
      Hotkeys = {
        OpenPauseMenu = pauseCombo;
        ShutdownVM = quitCombo;
        SaveStateToSlot = fn "LeftShoulder";
        LoadStateFromSlot = fn "+LeftTrigger";
        NextSaveStateSlot = fn "DPadUp";
        PreviousSaveStateSlot = fn "DPadDown";
        ToggleTurbo = fn "+RightTrigger";
        TogglePause = fn "B";
      };
    };
    # PPSSPP emulates the PSP firmware itself and needs no BIOS
    "${home}/.config/ppsspp/PSP/SYSTEM/ppsspp.ini" = {
      General = {
        FirstRun = "False";
        CheckForNewVersion = "False";
      };
      # Matches the RP6: Vulkan, 4x internal resolution, 16x anisotropic, linear filtering
      Graphics = {
        FullScreen = "True";
        GraphicsBackend = "3 (VULKAN)";
        InternalResolution = "4";
        AnisotropyLevel = "4";
        TextureFiltering = "1";
        BufferFiltering = "1";
      };
    };
  };

  iniLines = file: sections: lib.concatStrings (lib.mapAttrsToList (section: keys:
    lib.concatStrings (lib.mapAttrsToList (key: value: ''
      ${pkgs.crudini}/bin/crudini --set ${lib.escapeShellArgs [ file section key value ]}
    '') keys)) sections);

  # ES-DE's stock commands pass only -batch, so the emulator window shows before going
  # fullscreen and the start of the boot animation is lost in the switch. A custom
  # system replaces the bundled entry wholesale, hence the copied metadata.
  customSystems = pkgs.writeText "es_systems.xml" ''
    <?xml version="1.0"?>
    <systemList>
      <system>
        <name>psx</name>
        <fullname>Sony PlayStation</fullname>
        <path>%ROMPATH%/psx</path>
        <extension>.bin .BIN .cbn .CBN .ccd .CCD .chd .CHD .cue .CUE .ecm .ECM .exe .EXE .img .IMG .iso .ISO .m3u .M3U .mdf .MDF .mds .MDS .minipsf .MINIPSF .pbp .PBP .psexe .PSEXE .psf .PSF .toc .TOC .z .Z .znx .ZNX .7z .7Z .zip .ZIP</extension>
        <command label="DuckStation (Standalone)">%EMULATOR_DUCKSTATION% -batch -fullscreen -nogui -slowboot %ROM%</command>
        <platform>psx</platform>
        <theme>psx</theme>
      </system>
      <system>
        <name>ps2</name>
        <fullname>Sony PlayStation 2</fullname>
        <path>%ROMPATH%/ps2</path>
        <extension>.bin .BIN .chd .CHD .ciso .CISO .cso .CSO .desktop .dump .DUMP .elf .ELF .gz .GZ .m3u .M3U .mdf .MDF .img .IMG .iso .ISO .isz .ISZ .ngr .NRG .zso .ZSO</extension>
        <command label="PCSX2 (Standalone)">%EMULATOR_PCSX2% -batch -fullscreen -nogui -slowboot %ROM%</command>
        <platform>ps2</platform>
        <theme>ps2</theme>
      </system>
    </systemList>
  '';

  # RetroArch hotkeys use raw udev indices, read off the 8BitDo with evtest:
  # buttons 1 B, 4 L1, 6 Select, 7 Start, 8 Home; axes +2 L2, +5 R2
  retroarchSettings = {
    video_fullscreen = "true";
    quit_press_twice = "false";
    input_enable_hotkey_btn = "6";
    input_exit_emulator_btn = "7";
    input_menu_toggle_btn = "8";
    input_save_state_btn = "4";
    input_load_state_axis = "+2";
    input_state_slot_increase_btn = "h0up";
    input_state_slot_decrease_btn = "h0down";
    input_toggle_fast_forward_axis = "+5";
    input_pause_toggle_btn = "1";
    fastforward_ratio = fastForward;
  };

  # ES-DE stores a system's emulator choice in its gamelist.xml
  alternativeEmulators = {
    psx = "DuckStation (Standalone)";
    ps2 = "PCSX2 (Standalone)";
    psp = "PPSSPP (Standalone)";
  };

  altEmulatorLines = system: label: ''
    set_alt_emulator ${lib.escapeShellArgs [ system label ]}
  '';

  apply-emulator-settings = pkgs.writeShellScript "esde-apply-emulator-settings" ''
    ${lib.concatStrings (lib.mapAttrsToList (file: _: ''
      mkdir -p "$(dirname ${lib.escapeShellArg file})"
    '') emulatorSettings)}
    ${lib.concatStrings (lib.mapAttrsToList iniLines emulatorSettings)}

    set_alt_emulator() {
      gamelist="${home}/ES-DE/gamelists/$1/gamelist.xml"
      block="<alternativeEmulator>\n\t<label>$2</label>\n</alternativeEmulator>"
      mkdir -p "$(dirname "$gamelist")"
      if [ ! -s "$gamelist" ]; then
        printf '<?xml version="1.0"?>\n%b\n<gameList>\n</gameList>\n' "$block" > "$gamelist"
      elif ${pkgs.gnugrep}/bin/grep -q "<alternativeEmulator>" "$gamelist"; then
        ${pkgs.gnused}/bin/sed -i "/<alternativeEmulator>/,/<\/alternativeEmulator>/s|<label>.*</label>|<label>$2</label>|" "$gamelist"
      else
        ${pkgs.gnused}/bin/sed -i "0,/<gameList>/s|<gameList>|$block\n<gameList>|" "$gamelist"
      fi
    }
    ${lib.concatStrings (lib.mapAttrsToList altEmulatorLines alternativeEmulators)}

    # retroarch.cfg has no sections and quotes every value, so crudini does not fit
    set_ra() {
      cfg="${home}/.config/retroarch/retroarch.cfg"
      touch "$cfg"
      if ${pkgs.gnugrep}/bin/grep -q "^$1 = " "$cfg"; then
        ${pkgs.gnused}/bin/sed -i "s|^$1 = .*|$1 = \"$2\"|" "$cfg"
      else
        printf '%s = "%s"\n' "$1" "$2" >> "$cfg"
      fi
    }
    ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
      set_ra ${lib.escapeShellArgs [ k v ]}
    '') retroarchSettings)}
  '';

  # Reads every gamepad without grabbing it, so a short Home press still reaches the
  # emulator; only a press held past HOLD seconds suspends. Pads are rescanned for hotplug.
  homeHoldSuspend = pkgs.writers.writePython3 "gamepad-home-suspend" {
    libraries = [ pkgs.python3Packages.evdev ];
  } ''
    import asyncio
    import subprocess
    import time

    import evdev
    from evdev import ecodes

    HOLD = 2.0
    RESUME_GRACE = 10.0
    watched: set[str] = set()
    last_suspend = 0.0


    def is_gamepad(dev: evdev.InputDevice) -> bool:
        keys = dev.capabilities().get(ecodes.EV_KEY, [])
        return ecodes.BTN_MODE in keys and ecodes.BTN_SOUTH in keys


    async def suspend_after_hold() -> None:
        global last_suspend
        await asyncio.sleep(HOLD)
        if time.monotonic() - last_suspend > RESUME_GRACE:
            last_suspend = time.monotonic()
            subprocess.run(["systemctl", "suspend"], check=False)


    async def watch(dev: evdev.InputDevice) -> None:
        timer = None
        try:
            async for ev in dev.async_read_loop():
                if ev.type != ecodes.EV_KEY or ev.code != ecodes.BTN_MODE:
                    continue
                if ev.value == 1:
                    timer = asyncio.create_task(suspend_after_hold())
                elif ev.value == 0 and timer:
                    timer.cancel()
        except OSError:
            pass
        finally:
            if timer:
                timer.cancel()
            watched.discard(dev.path)


    async def main() -> None:
        while True:
            for path in evdev.list_devices():
                if path in watched:
                    continue
                try:
                    dev = evdev.InputDevice(path)
                except OSError:
                    continue
                if is_gamepad(dev):
                    watched.add(path)
                    asyncio.create_task(watch(dev))
                else:
                    dev.close()
            await asyncio.sleep(2)


    asyncio.run(main())
  '';

  # Fullscreen gamescope session; quitting ES-DE relaunches it, like Kodi on bragi
  couch-session = pkgs.writeShellScript "couch-session" ''
    exec ${pkgs.gamescope}/bin/gamescope -f -- ${pkgs.bash}/bin/bash -c \
      'while true; do ${apply-settings}; ${apply-emulator-settings}; ${es-de}/bin/es-de; sleep 1; done'
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
        # Quitting ES-DE only relaunches it here, so expose Reboot and Power Off instead
        ShowQuitMenu = true;
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
      # WirePlumber starts unseen outputs at 40%, too quiet into an AVR;
      # level is then set on the AVR. Saved per-device volume still wins.
      wireplumber.extraConfig."90-default-volume" = {
        "wireplumber.settings"."device.routes.default-sink-volume" = 1.0;
      };
      # A suspended HDMI sink makes the AVR relock on every game launch, swallowing
      # the first seconds of audio such as the PS1 boot chime
      wireplumber.configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/11-no-suspend.conf" ''
          monitor.alsa.rules = [
            {
              "matches": [ { "node.name": "~alsa_output.*" } ],
              "actions": { "update-props": {
                "session.suspend-timeout-seconds": 0
              } }
            }
          ]
        '')
      ];
    };

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${couch-session}";
        inherit (cfg) user;
      };
    };

    # Rest mode like a console: suspend only on request (power button or a held Home),
    # never on idle. Hibernate stays off; there is no swap partition to resume from.
    systemd.targets = {
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
    services.logind.settings.Login = {
      HandlePowerKey = "suspend";
      IdleAction = "ignore";
    };

    # The 8BitDo dongle lacks USB remote wakeup (bmAttributes 0x80), so pads can only
    # put the box to sleep; waking is the power button or the keyboard dongle.
    systemd.services.gamepad-home-suspend = {
      description = "Suspend when a gamepad's Home button is held";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = homeHoldSuspend;
        Restart = "always";
      };
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
          # The RP6's PPSSPP memory stick lives on its SD card under ROMs/psp/PSP
          ppsspp-saves = {
            label = "PPSSPP";
            path = "${home}/.config/ppsspp/PSP/SAVEDATA";
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
      "d ${home}/ES-DE/custom_systems 0755 ${cfg.user} users -"
      "L+ ${home}/ES-DE/custom_systems/es_systems.xml - - - - ${customSystems}"
      "d ${home}/Emulation 0755 ${cfg.user} users -"
      "d ${home}/Emulation/bios 0755 ${cfg.user} users -"
      "d ${home}/.config 0755 ${cfg.user} users -"
      "d ${home}/.config/retroarch 0755 ${cfg.user} users -"
      "d ${home}/.config/PCSX2 0755 ${cfg.user} users -"
      "d ${home}/.config/ppsspp 0755 ${cfg.user} users -"
      "d ${home}/.config/ppsspp/PSP 0755 ${cfg.user} users -"
      "d ${home}/.config/ppsspp/PSP/SAVEDATA 0755 ${cfg.user} users -"
      # Each emulator reads its BIOS from the one synced folder
      "L+ ${home}/.config/retroarch/system - - - - ${home}/Emulation/bios"
      "L+ ${home}/.config/PCSX2/bios - - - - ${home}/Emulation/bios"
    ];

    # Standalone PPSSPP: the libretro core ships without the assets it needs
    environment.systemPackages = [ es-de duckstation retroarch pkgs.pcsx2 pkgs.ppsspp-sdl ];
  };
}
