{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ usbutils ];

  services.udev.packages = with pkgs; [ betaflight-configurator ];
}
