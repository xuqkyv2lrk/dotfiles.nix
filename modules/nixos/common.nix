{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ usbutils ];

  programs.nix-ld.enable = true;
}
