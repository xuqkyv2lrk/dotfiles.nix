{ pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [ usbutils ];

  programs.nix-ld.enable = true;

  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 video_nr=2 card_label="Iriun Webcam"
  '';
}
