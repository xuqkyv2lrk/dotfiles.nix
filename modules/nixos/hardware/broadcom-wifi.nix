{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/hardware/network/broadcom-43xx.nix")
  ];

  # Broadcom firmware is unfree
  nixpkgs.config.allowUnfree = true;
}
