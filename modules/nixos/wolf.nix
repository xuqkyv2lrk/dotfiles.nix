{ config, lib, pkgs, ... }:
let
  cfg = config.services.wolf-guest;
  stateDir = "/var/lib/wolf";

  # One app only: the guest's own ES-DE. The library is shared read-only; saves,
  # states and settings live in Wolf's per-client home under ${stateDir}.
  guestConfig = pkgs.writeText "wolf-config.toml" ''
    hostname = "${cfg.hostname}"
    config_version = 7
    paired_clients = []

    [[profiles]]
    id = "moonlight-profile-id"

    [[profiles.apps]]
    title = "EmulationStation"
    icon_png_path = "https://games-on-whales.github.io/wildlife/apps/es-de/assets/icon.png"

    [profiles.apps.runner]
    type = "docker"
    name = "WolfES-DE"
    # not :fedora, whose esde.AppImage is an aarch64 build (Exec format error on x86)
    image = "ghcr.io/games-on-whales/es-de:edge"
    mounts = ["${cfg.romDir}:/ROMs:ro", "${cfg.biosDir}:/bioses:ro"]
    env = ["RUN_SWAY=1", "GOW_REQUIRED_DEVICES=/dev/input/* /dev/dri/*"]
    devices = []
    ports = []
    base_create_json = """
    {
      "HostConfig": {
        "IpcMode": "host",
        "Privileged": false,
        "CapAdd": ["NET_RAW", "MKNOD", "NET_ADMIN"],
        "DeviceCgroupRules": ["c 13:* rmw", "c 244:* rmw"]
      }
    }
    """

    ${builtins.readFile ./wolf-gstreamer.toml}
  '';

  ports = {
    https = 47884;
    http = 47889;
    control = 47899;
    rtsp = 47910;
    # Wolf's defaults; Sunshine's streams sit at 47998-48010
    video = 48100;
    audio = 48200;
  };
in
{
  options.services.wolf-guest = {
    enable = lib.mkEnableOption "a separate Wolf streaming session for a remote guest";
    hostname = lib.mkOption { type = lib.types.str; default = "idavoll-guest"; };
    romDir = lib.mkOption { type = lib.types.str; };
    biosDir = lib.mkOption { type = lib.types.str; };
    interface = lib.mkOption {
      type = lib.types.str;
      description = "The only interface Wolf's ports are opened on.";
    };
    uid = lib.mkOption {
      type = lib.types.int;
      default = 2000;
      description = "uid/gid the guest's apps run as; must not match any host user.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    hardware.uinput.enable = true;

    # Owns the guest's virtual pads, so the host user (in `input`) cannot open them.
    # The couch session reads /dev/input directly (SDL_JOYSTICK_DISABLE_UDEV), so the
    # seat9 tag alone would not keep the guest's pad out of it.
    users.groups.wolf-guest.gid = cfg.uid;

    services.udev.extraRules = ''
      SUBSYSTEM=="input", ATTR{name}=="Wolf *virtual*", MODE="0660", GROUP="wolf-guest", ENV{ID_SEAT}="seat9", TAG-="uaccess"
      SUBSYSTEMS=="input", ATTRS{name}=="Wolf *virtual*", MODE="0660", GROUP="wolf-guest", ENV{ID_SEAT}="seat9", TAG-="uaccess"
      KERNEL=="hidraw*", ATTRS{uevent}=="*HID_NAME=Wolf *virtual*", MODE="0660", GROUP="wolf-guest", ENV{ID_SEAT}="seat9", TAG-="uaccess"
    '';

    networking.firewall.interfaces.${cfg.interface} = {
      allowedTCPPorts = [ ports.https ports.http ports.rtsp ];
      allowedUDPPorts = [ ports.control ports.video ports.audio ];
    };

    # Wolf rewrites config.toml when a client pairs, so seed it once and leave it
    systemd.tmpfiles.rules = [
      "d ${stateDir} 0750 root root -"
      "d ${stateDir}/cfg 0750 root root -"
      "C ${stateDir}/cfg/config.toml 0640 root root - ${guestConfig}"
    ];

    virtualisation.oci-containers = {
      backend = "docker";
      containers.wolf = {
        image = "ghcr.io/games-on-whales/wolf:stable";
        extraOptions = [
          "--network=host"
          "--device=/dev/dri/"
          "--device=/dev/uinput"
          "--device=/dev/uhid"
          "--device-cgroup-rule=c 13:* rmw"
        ];
        volumes = [
          "${stateDir}:/etc/wolf:rw"
          "/var/run/docker.sock:/var/run/docker.sock:rw"
          "/dev/:/dev/:rw"
          "/run/udev:/run/udev:rw"
        ];
        environment = {
          WOLF_HTTP_PORT = toString ports.http;
          WOLF_HTTPS_PORT = toString ports.https;
          WOLF_CONTROL_PORT = toString ports.control;
          WOLF_RTSP_SETUP_PORT = toString ports.rtsp;
          WOLF_VIDEO_PING_PORT = toString ports.video;
          WOLF_AUDIO_PING_PORT = toString ports.audio;
          WOLF_RENDER_NODE = "/dev/dri/renderD128";
          WOLF_DEFAULT_RUN_UID = toString cfg.uid;
          WOLF_DEFAULT_RUN_GID = toString cfg.uid;
        };
      };
    };
  };
}
