{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.lan-mouse ];

  # lan-mouse default port
  networking.firewall.allowedUDPPorts = [ 4242 ];

  # Per-user service for every user; pairing stays in each user's
  # ~/.config/lan-mouse/config.toml (authorized fingerprints), left unmanaged.
  systemd.user.services.lan-mouse = {
    description = "lan-mouse software KVM";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      # backend left to auto-detect: wlroots on niri/Umbriel, libei on GNOME/KDE
      ExecStart = "${pkgs.lan-mouse}/bin/lan-mouse daemon";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
