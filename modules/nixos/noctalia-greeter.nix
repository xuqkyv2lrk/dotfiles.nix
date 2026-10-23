{ pkgs, config, lib, ... }:
{
  services.seatd.enable = true;

  # niri-session runs `systemctl --user import-environment` without names, which systemd 262
  # warns about on the console. greetd runs the session on the VT (SDDM hid it in the journal),
  # so the Niri session entry sends the session output to the journal instead.
  programs.niri.package = pkgs.symlinkJoin {
    name = "niri-${pkgs.niri.version}-journal-session";
    paths = [ pkgs.niri ];
    postBuild = ''
      cp --remove-destination ${pkgs.niri}/share/wayland-sessions/niri.desktop \
        $out/share/wayland-sessions/niri.desktop
      chmod u+w $out/share/wayland-sessions/niri.desktop
      substituteInPlace $out/share/wayland-sessions/niri.desktop \
        --replace-fail "Exec=niri-session" "Exec=${pkgs.writeShellScript "niri-session-journal" ''
          exec ${pkgs.systemd}/bin/systemd-cat -t niri-session ${pkgs.niri}/bin/niri-session
        ''}"
    '';
    passthru = pkgs.niri.passthru // { providedSessions = [ "niri" ]; };
  };

  services.displayManager.noctalia-greeter = {
    enable = true;
    # Lets the shell push the wallpaper and palette without an admin prompt.
    passwordlessSyncUsers = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
    settings = {
      keyboard.layout = "us";
      cursor.size = 24;
      appearance = {
        scheme = "Synced";
        theme_mode = "dark";
        password_style = "random";
        # Catppuccin Mocha with the lavender primary, the same palette as the shell.
        palette = {
          primary = "#b4befe";
          on_primary = "#11111b";
          secondary = "#f5c2e7";
          on_secondary = "#11111b";
          tertiary = "#cba6f7";
          on_tertiary = "#11111b";
          error = "#f38ba8";
          on_error = "#11111b";
          surface = "#1e1e2e";
          on_surface = "#cdd6f4";
          surface_variant = "#313244";
          on_surface_variant = "#a6adc8";
          outline = "#45475a";
          shadow = "#11111b";
          hover = "#cba6f7";
          on_hover = "#11111b";
        };
      };
    };
  };
}
