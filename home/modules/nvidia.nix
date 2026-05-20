{ ... }:
{
  # Plex Desktop: use VAAPI-copy for hardware decode via NVDEC.
  # vaapi-copy avoids the EGL interop requirement that breaks under XWayland.
  home.file.".local/share/plex/mpv.conf".text = ''
    hwdec=vaapi-copy
    hwdec-codecs=all
  '';
}
