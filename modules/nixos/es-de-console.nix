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

  duckstationImage = rec {
    pname = "duckstation";
    version = "0.1-12083";
    src = pkgs.fetchurl {
      url = "https://github.com/stenzek/duckstation/releases/download/v${version}/DuckStation-x64.AppImage";
      hash = "sha256-xebwRfaiQggvyvqfAtVq2JXiM7lCcoeI0jKtDAx2XCQ=";
    };
  };
  duckstation = pkgs.appimageTools.wrapType2 duckstationImage;
  duckstationResources = "${pkgs.appimageTools.extract duckstationImage}/usr/bin/resources";

  # The synced folder keeps the RP6's state layout; DuckStation here saves to its own
  # folder and psx_state_sync.py maps the quick slot between the two
  syncedStates = "${home}/.local/share/duckstation/savestates";
  localStates = "${home}/.local/share/duckstation-states";
  psxStateSync = pkgs.writeShellScript "psx-state-sync" ''
    exec ${pkgs.python3}/bin/python3 -I ${./psx_state_sync.py} \
      --synced ${lib.escapeShellArg syncedStates} \
      --local ${lib.escapeShellArg localStates} \
      --rom-dir ${lib.escapeShellArg "${home}/ROMs/psx"} \
      --uri-prefix ${lib.escapeShellArg cfg.saveSync.psxAndroidRomUri} \
      --disc-sets ${duckstationResources}/discsets.yaml \
      --db ${lib.escapeShellArg "${home}/.local/state/psx-state-sync.json"} \
      --only ${lib.escapeShellArgs cfg.saveSync.psxStateSerials}
  '';

  # Each core is ES-DE's default for its system, so no emulator pin is needed; ES-DE
  # finds them under /run/current-system/sw/lib/retroarch/cores
  retroarch = pkgs.retroarch.withCores (cores: with cores; [
    mesen # NES, Famicom Disk System (disksys.rom)
    snes9x
    mgba # GB, GBC, GBA (gba_bios.bin)
    flycast # Dreamcast (dc/dc_boot.bin)
    fbneo # Neo Geo (neogeo.zip) and arcade; needs short set names like vendettaj.zip
  ]);

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
        # Writes <serial>_resume.sav on quit; psx-state-sync only maps the quick slot,
        # so this never reaches the RP6
        SaveStateOnExit = "true";
      };
      Folders.SaveStates = localStates;
      # Nix pins the version; an update prompt only stalls the launch
      AutoUpdater.CheckAtStartup = "false";
      # On-screen messages vanish under gamescope; the file keeps them readable over ssh
      Logging = {
        LogToFile = "true";
        LogFileTimestamps = "true";
      };
      BIOS = {
        SearchDirectory = bios;
        # The PSP-extracted BIOS plays better than the real dumps, at the cost of
        # the white Sony intro, so it covers every region
        PathNTSCU = "psxonpsp660.bin";
        PathNTSCJ = "psxonpsp660.bin";
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
      # Loading a state made on the RP6 warns about BIOS, port 2, memory card and disc
      # path differences; hide warnings but keep info and error messages
      Display.OSDWarningDuration = "0";
      Hotkeys = {
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
        # A resume state on every quit, so a lost controller never costs progress
        SaveStateOnShutdown = "true";
      };
      Framerate.TurboScalar = fastForward;
      # Renderer 14 is Vulkan; 2x is the safe ceiling for the iGPU in heavier games
      "EmuCore/GS" = {
        Renderer = "14";
        upscale_multiplier = "2";
      };
      Hotkeys = {
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
    # PPSSPP's SDL build reports LB/RB as 10-193/10-192 ("Button 6"/"Button 5", set
    # on the couch), but its default map binds L/R to 10-194/10-195, leaving the
    # bumpers dead. 1-45/1-51 keep keyboard Q/W.
    "${home}/.config/ppsspp/PSP/SYSTEM/controls.ini" = {
      ControlMapping = {
        L = "1-45,10-193";
        R = "1-51,10-192";
        # Select+Start quits back to ES-DE like the other emulators; ':' joins a chord
        "Exit App" = "10-196:10-197";
      };
    };
  };

  # Bindings with a keyboard fallback. Both emulators store extra bindings for one
  # action as repeated keys, which crudini cannot write; Esc opens the pause menu.
  multiBindings = {
    "${home}/.local/share/duckstation/settings.ini".Hotkeys.OpenPauseMenu = [ pauseCombo "Keyboard/Escape" ];
    "${home}/.config/PCSX2/inis/PCSX2.ini".Hotkeys.OpenPauseMenu = [ pauseCombo "Keyboard/Escape" ];
  };

  # Replaces every line of a key inside one section with the given values, in order
  setMultiKey = pkgs.writers.writePython3 "ini-set-multi" { } ''
    import sys
    from pathlib import Path

    path, section, key, *values = sys.argv[1:]
    file = Path(path)
    lines = file.read_text().splitlines() if file.exists() else []
    out: list[str] = []
    current = None
    placed = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            if current == section and not placed:
                out += [f"{key} = {v}" for v in values]
                placed = True
            current = stripped[1:-1]
            out.append(line)
            continue
        if current == section and stripped.split("=", 1)[0].strip() == key:
            continue
        out.append(line)
    if not placed:
        if current != section:
            out.append(f"[{section}]")
        out += [f"{key} = {v}" for v in values]
    file.write_text("\n".join(out) + "\n")
  '';

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
      <!-- Standalone only: the ROM sync replaces gamelist.xml, which drops the
           alternativeEmulator pick and fell back to the absent RetroArch core -->
      <system>
        <name>psp</name>
        <fullname>Sony PlayStation Portable</fullname>
        <path>%ROMPATH%/psp</path>
        <extension>.chd .CHD .cso .CSO .elf .ELF .iso .ISO .pbp .PBP .prx .PRX .7z .7Z .zip .ZIP</extension>
        <command label="PPSSPP (Standalone)">%EMULATOR_PPSSPP% %ROM%</command>
        <platform>psp</platform>
        <theme>psp</theme>
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
    # The core-logo splash RetroArch plays before every game
    menu_show_load_content_animation = "false";
    # Pace to the core's own frame rate, not the 120 Hz display, so games keep
    # normal speed and VRR shows each frame on time
    vrr_runloop_enable = "true";
  } // retroarchPads;

  # No autoconfig profile in RetroArch matches the Ultimate 2C, so every player is
  # bound by hand. Udev numbers buttons by evdev code: 0 A, 1 B, 2 X, 3 Y, 4 LB,
  # 5 RB, 6 Select, 7 Start, 9 L3, 10 R3; axes 0/1 left stick, 2 LT, 3/4 right, 5 RT.
  # The RetroPad is SNES-shaped: its b is the bottom button and a the right one.
  retroarchPads = lib.foldl' (acc: n: acc // lib.mapAttrs' (k: v:
    lib.nameValuePair "input_player${toString n}_${k}" v) {
      joypad_index = toString (n - 1);
      b_btn = "0";
      a_btn = "1";
      y_btn = "2";
      x_btn = "3";
      l_btn = "4";
      r_btn = "5";
      select_btn = "6";
      start_btn = "7";
      l3_btn = "9";
      r3_btn = "10";
      l2_axis = "+2";
      r2_axis = "+5";
      up_btn = "h0up";
      down_btn = "h0down";
      left_btn = "h0left";
      right_btn = "h0right";
      l_x_minus_axis = "-0";
      l_x_plus_axis = "+0";
      l_y_minus_axis = "-1";
      l_y_plus_axis = "+1";
      r_x_minus_axis = "-3";
      r_x_plus_axis = "+3";
      r_y_minus_axis = "-4";
      r_y_plus_axis = "+4";
    }) { } [ 1 2 3 4 ];

  # ES-DE stores a system's emulator choice in its gamelist.xml
  alternativeEmulators = {
    # FinalBurn Neo runs most arcade sets faster than current MAME on the iGPU
    arcade = "FinalBurn Neo";
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
    ${lib.concatStrings (lib.mapAttrsToList (file: sections: lib.concatStrings (lib.mapAttrsToList (section: keys:
      lib.concatStrings (lib.mapAttrsToList (key: values: ''
        ${setMultiKey} ${lib.escapeShellArgs ([ file section key ] ++ values)}
      '') keys)) sections)) multiBindings)}

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
  # Select+R3 saves a clip and Select+L3 toggles live streaming; no emulator binds them.
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
    USER = "${cfg.user}"
    watched: set[str] = set()
    last_suspend = 0.0


    def user_systemctl(*args: str) -> int:
        cmd = ["systemctl", "--user", "-M", f"{USER}@", *args]
        return subprocess.run(cmd, check=False).returncode


    def save_clip() -> None:
        # main only: gsr-kms-server would die from SIGUSR1's default action
        user_systemctl("kill", "--signal=SIGUSR1", "--kill-whom=main",
                       "gsr-replay.service")


    def toggle_stream() -> None:
        if user_systemctl("is-active", "--quiet", "gsr-stream.service") == 0:
            user_systemctl("stop", "--no-block", "gsr-stream.service")
        else:
            user_systemctl("start", "--no-block", "gsr-stream.service")


    def is_gamepad(dev: evdev.InputDevice) -> bool:
        keys = dev.capabilities().get(ecodes.EV_KEY, [])
        return ecodes.BTN_MODE in keys and ecodes.BTN_SOUTH in keys


    async def suspend_after_hold() -> None:
        global last_suspend
        await asyncio.sleep(HOLD)
        if time.monotonic() - last_suspend > RESUME_GRACE:
            last_suspend = time.monotonic()
            subprocess.run(["systemctl", "suspend"], check=False)


    COMBOS = {ecodes.BTN_THUMBR: save_clip, ecodes.BTN_THUMBL: toggle_stream}


    async def watch(dev: evdev.InputDevice) -> None:
        timer = None
        select_held = False
        try:
            async for ev in dev.async_read_loop():
                if ev.type != ecodes.EV_KEY:
                    continue
                if ev.code == ecodes.BTN_SELECT:
                    select_held = ev.value != 0
                elif ev.value == 1 and select_held and ev.code in COMBOS:
                    asyncio.create_task(asyncio.to_thread(COMBOS[ev.code]))
                elif ev.code != ecodes.BTN_MODE:
                    continue
                elif ev.value == 1:
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

  clipSeconds = 15;
  clipDir = "${home}/Videos/clips";
  streamEnv = "${home}/.config/gsr/stream.env";
  sounds = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo";
  gsr = "/run/current-system/sw/bin/gpu-screen-recorder";
  gsrCapture = "-w screen -f 60 -a default_output";
  # gsr needs a display connection even for KMS capture; user units get none
  gsrEnv = "WAYLAND_DISPLAY=gamescope-0";

  # Confirms a clip or stream toggle: rumbles every pad that can, else plays a short
  # freedesktop sound. Runs as the console user, who reads pads via the input group.
  gamepadFeedback = pkgs.writers.writePython3 "gamepad-feedback" {
    libraries = [ pkgs.python3Packages.evdev ];
    flakeIgnore = [ "E501" ];
  } ''
    import subprocess
    import sys
    import time

    import evdev
    from evdev import InputDevice, ecodes, ff

    # rumble pulses in ms (a double tap, rising, falling), and the fallback sound
    PATTERNS = {
        "clip": ([60, 60], "${sounds}/camera-shutter.oga"),
        "live": ([70, 70, 250], "${sounds}/service-login.oga"),
        "off": ([250, 70], "${sounds}/service-logout.oga"),
    }
    GAP = 0.07


    def rumble(dev: InputDevice, pulses: list[int]) -> None:
        for ms in pulses:
            effect = ff.Effect(
                ecodes.FF_RUMBLE, -1, 0, ff.Trigger(0, 0), ff.Replay(ms, 0),
                ff.EffectType(ff_rumble_effect=ff.Rumble(0xC000, 0xC000)),
            )
            eid = dev.upload_effect(effect)
            dev.write(ecodes.EV_FF, eid, 1)
            time.sleep(ms / 1000 + GAP)
            dev.erase_effect(eid)


    def can_rumble(dev: InputDevice) -> bool:
        caps = dev.capabilities()
        has_ff = ecodes.FF_RUMBLE in caps.get(ecodes.EV_FF, [])
        return has_ff and ecodes.BTN_SOUTH in caps.get(ecodes.EV_KEY, [])


    def main() -> None:
        pulses, sound = PATTERNS[sys.argv[1]]
        rumbled = False
        for path in evdev.list_devices():
            try:
                dev = InputDevice(path)
                if can_rumble(dev):
                    rumble(dev, pulses)
                    rumbled = True
                dev.close()
            except OSError:
                continue
        if not rumbled:
            subprocess.run(["${pkgs.pipewire}/bin/pw-play", sound], check=False)


    main()
  '';

  # gpu-screen-recorder passes the clip path and type; only the confirmation matters
  clipSaved = pkgs.writeShellScript "clip-saved" ''
    exec ${gamepadFeedback} clip
  '';

  # Fullscreen gamescope session; quitting ES-DE relaunches it, like Kodi on bragi.
  # Apps render at 1080p, matching the emulators' internal resolutions (PPSSPP 4x,
  # PCSX2 2x). Unpinned, gamescope followed the TV's 4K mode on some boots, shrinking
  # the UI and adding input lag on the iGPU. 1080p120 fits the iGPU's HDMI 2.0, and
  # the C3's VRR range (40-120 Hz) lets each emulator run at its native rate.
  # Output goes to the journal (journalctl -t gamescope) instead of the console.
  # AppImage emulators (DuckStation, PCSX2) bundle their own libudev and never saw a
  # pad that powered off and back on; plain /dev/input watching catches the re-add.
  couch-session = pkgs.writeShellScript "couch-session" ''
    export SDL_JOYSTICK_DISABLE_UDEV=1
    exec ${pkgs.systemd}/bin/systemd-cat -t gamescope ${pkgs.gamescope}/bin/gamescope -f -W 1920 -H 1080 -w 1920 -h 1080 -r 120 --adaptive-sync -- ${pkgs.bash}/bin/bash -c \
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

    saveSync.psxAndroidRomUri = lib.mkOption {
      type = lib.types.str;
      description = ''
        SAF URI prefix the Android DuckStation records for the PSX ROM folder, up to
        and including the encoded trailing slash; read it from an RP6 state header.
      '';
    };

    saveSync.psxStateSerials = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Limit state translation to these serials; empty means every game.";
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

    # Boots straight into the newest generation; holding Space at power-on still opens
    # the systemd-boot menu for a rollback. The boot log stays visible on purpose.
    boot.loader.timeout = 0;
    # amdgpu loads early and starts in gamescope's mode, so the TV and Denon re-sync
    # once at boot instead of again when gamescope starts
    boot.initrd.kernelModules = [ "amdgpu" ];
    boot.kernelParams = [ "video=HDMI-A-1:1920x1080@120" ];

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
      description = "Suspend on a held Home; clip and stream button combos";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = homeHoldSuspend;
        Restart = "always";
      };
    };

    # Captures the screen through the setcap'd gsr-kms-server wrapper
    programs.gpu-screen-recorder.enable = true;

    # Xbox-style instant replay held in RAM; Select+R3 (SIGUSR1) writes it out.
    # Restarts until gamescope has a display to capture.
    systemd.user.services.gsr-replay = {
      description = "Keep the last ${toString clipSeconds} s of gameplay for clips";
      wantedBy = [ "default.target" ];
      conflicts = [ "gsr-stream.service" ];
      unitConfig.ConditionUser = cfg.user;
      serviceConfig = {
        Environment = gsrEnv;
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${clipDir}";
        # AAC: phones and most sites will not play Opus inside MP4
        ExecStart = "${gsr} ${gsrCapture} -k hevc -c mp4 -ac aac -bm cbr -q 20000 -r ${toString clipSeconds} -sc ${clipSaved} -o ${clipDir}";
        Restart = "always";
        RestartSec = 5;
      };
    };

    # Select+L3 swaps the replay buffer for a live stream and back. The RTMP URL with
    # its stream key stays out of git, in a file holding STREAM_URL=rtmp://...
    systemd.user.services.gsr-stream = {
      description = "Live stream gameplay to the RTMP URL in ${streamEnv}";
      conflicts = [ "gsr-replay.service" ];
      unitConfig = {
        ConditionUser = cfg.user;
        ConditionPathExists = streamEnv;
      };
      serviceConfig = {
        Environment = gsrEnv;
        EnvironmentFile = streamEnv;
        # H.264 CBR at 6000 kbps: the most Twitch ingests without enhanced broadcasting
        ExecStart = "${gsr} ${gsrCapture} -k h264 -c flv -bm cbr -q 6000 -o \${STREAM_URL}";
        ExecStartPost = "${gamepadFeedback} live";
        ExecStopPost = [
          "${gamepadFeedback} off"
          "${pkgs.systemd}/bin/systemctl --user --no-block start gsr-replay.service"
        ];
      };
    };

    systemd.services.psx-state-sync = {
      description = "Translate DuckStation quick-save states between the RP6 and here";
      wantedBy = [ "multi-user.target" ];
      after = [ "syncthing.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = psxStateSync;
      };
    };
    systemd.paths.psx-state-sync = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = [ syncedStates localStates ];
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
          clips = {
            label = "Clips";
            path = clipDir;
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
      "d ${localStates} 0755 ${cfg.user} users -"
      "L+ ${home}/.local/share/duckstation/.stignore - - - - ${duckstation-stignore}"
      "d ${home}/ES-DE 0755 ${cfg.user} users -"
      "d ${home}/ES-DE/themes 0755 ${cfg.user} users -"
      "L+ ${home}/ES-DE/themes/${cfg.theme.name} - - - - ${cfg.theme.src}"
      "d ${home}/ES-DE/custom_systems 0755 ${cfg.user} users -"
      "L+ ${home}/ES-DE/custom_systems/es_systems.xml - - - - ${customSystems}"
      "d ${home}/Emulation 0755 ${cfg.user} users -"
      "d ${home}/Emulation/bios 0755 ${cfg.user} users -"
      "d ${home}/Videos 0755 ${cfg.user} users -"
      "d ${clipDir} 0755 ${cfg.user} users -"
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
