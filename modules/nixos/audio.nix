{ pkgs, ... }:
{
  # Behringer UV1: disable autoclock to prevent USB clock drift stuttering.
  boot.extraModprobeConfig = ''
    options snd_usb_audio implicit_fb=1 ignore_ctl_error=1 autoclock=0
  '';

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Use configPackages (raw SPA-JSON) instead of extraConfig because NixOS's
  # WirePlumber config serializer silently drops the second rule in a
  # monitor.alsa.rules list, leaving the node-level api.alsa.* props unset.
  services.pipewire.wireplumber.configPackages = [
    (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-pro-audio.conf" ''
      monitor.alsa.rules = [
        {
          matches = [{ device.name = ~alsa_card\.usb-Behringer_UV1.* }]
          actions = {
            update-props = {
              device.profile = pro-audio
            }
          }
        }
        {
          matches = [{ node.name = ~alsa_.+\.usb-Behringer_UV1.* }]
          actions = {
            update-props = {
              audio.rate     = 192000
              audio.format   = S24_3LE
              api.alsa.period-size = 512
              api.alsa.headroom    = 4
            }
          }
        }
      ]
    '')
  ];

  services.pipewire.extraConfig.pipewire."92-low-latency" = {
    "context.properties" = {
      # Drive the graph at 192k so no resampling occurs on the UV1 path.
      "default.clock.rate" = 192000;
      "default.clock.allowed-rates" = [ 44100 48000 88200 96000 192000 ];

      "default.clock.quantum" = 1024;
      "default.clock.min-quantum" = 32;
      "default.clock.max-quantum" = 2048;
    };
  };
}
