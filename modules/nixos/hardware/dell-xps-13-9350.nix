{ pkgs, inputs, ... }:
{
  imports = [
    ./broadcom-wifi.nix
  ];

  # BCM4350 Bluetooth requires firmware not included in linux-firmware.
  hardware.firmware = [
    (pkgs.runCommand "bcm4350-bluetooth-firmware" {} ''
      mkdir -p $out/lib/firmware/brcm
      cp ${inputs.dotfiles-bootstrap}/core/system_components/xps_13_9350/bluetooth/BCM4350C5_003.006.007.0095.1703.hcd \
        $out/lib/firmware/brcm/BCM4350C5-0a5c-6412.hcd
    '')
  ];
}
