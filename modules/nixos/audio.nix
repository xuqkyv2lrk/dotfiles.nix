{ ... }:
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
}
