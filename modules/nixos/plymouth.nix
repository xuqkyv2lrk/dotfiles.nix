{ lib, pkgs, ... }: {
  boot.plymouth = {
    enable = true;
    theme = "tech_b";
    themePackages = [ pkgs.adi1090x-plymouth-themes ];
  };

  # Smooth handoff between Plymouth and the compositor
  boot.initrd.systemd.enable = true;

  # Quit Plymouth as soon as the display manager is ready, not after session start
  systemd.services.plymouth-quit = {
    after = lib.mkForce [ "display-manager.service" ];
    wants = lib.mkForce [ "display-manager.service" ];
  };

  # Suppress Plymouth on shutdown/reboot — only show it on boot
  systemd.services.plymouth-reboot.enable = false;
  systemd.services.plymouth-halt.enable = false;
  systemd.services.plymouth-poweroff.enable = false;
  systemd.services.plymouth-kexec.enable = false;

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
