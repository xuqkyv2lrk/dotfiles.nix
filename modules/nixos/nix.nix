{ pkgs, lib, ... }: {
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  # Keep the last 5 system generations, then collect unreferenced store paths
  systemd.services.nix-gc.serviceConfig.ExecStart = lib.mkForce (toString (
    pkgs.writeShellScript "nix-gc" ''
      ${pkgs.nix}/bin/nix-env \
        -p /nix/var/nix/profiles/system \
        --delete-generations +5
      ${pkgs.nix}/bin/nix-collect-garbage
    ''
  ));

  boot.loader.systemd-boot.configurationLimit = 5;
}
