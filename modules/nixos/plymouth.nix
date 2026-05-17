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

  # Suppress kernel/systemd output so Plymouth is the only thing visible
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "vt.global_cursor_default=0"
  ];
  boot.consoleLogLevel = 0;
}
