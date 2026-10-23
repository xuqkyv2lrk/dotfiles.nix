{ ... }:
{
  services.seatd.enable = true;

  services.displayManager.noctalia-greeter = {
    enable = true;
    # Lets the shell push the wallpaper and palette without an admin prompt.
    passwordlessSyncUsers = [ "x0xgo" ];
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
