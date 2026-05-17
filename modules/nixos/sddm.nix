{ ... }: {
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    silent = {
      enable = true;
      theme = "catppuccin-mocha";
    };
  };
}
