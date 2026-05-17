{ inputs, pkgs, ... }: {
  boot.plymouth = {
    enable = true;
    theme = "mac-style";
    themePackages = [
      inputs.s4rchiso-plymouth.packages.${pkgs.system}.default
    ];
  };

  # Smooth handoff between Plymouth and the compositor
  boot.initrd.systemd.enable = true;
}
