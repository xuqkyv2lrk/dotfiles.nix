{ ... }:
{
  hardware.asus.enable = true;

  services.asusd.enable = true;
  services.supergfxd.enable = true;

  boot.initrd.kernelModules = [ "amdgpu" ];
}
