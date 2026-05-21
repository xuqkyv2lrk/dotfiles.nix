{ pkgs, ... }:
{
  # Wrapper that forces Plex Desktop onto the native Wayland backend so Qt's
  # render loop receives proper vsync callbacks from Niri. Without this it
  # runs under XWayland, which stalls mpv_render_context_render() and causes
  # stuttering.
  home.file.".local/bin/plex-wayland" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec env QT_QPA_PLATFORM=wayland plex-desktop "$@"
    '';
  };

  xdg.desktopEntries.plex-desktop = {
    name = "Plex";
    exec = "plex-wayland";
    icon = "${pkgs.plex-desktop}/share/icons/hicolor/scalable/apps/plex-desktop.png";
    terminal = false;
    categories = [ "AudioVideo" "Audio" "Video" "Player" ];
  };

  # nvdec-copy uses NVIDIA's native decoder directly rather than going through
  # the VAAPI abstraction layer.
  home.file.".local/share/plex/mpv.conf".text = ''
    hwdec=nvdec-copy
    hwdec-codecs=all
  '';
}
