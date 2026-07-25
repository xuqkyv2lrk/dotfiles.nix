{ ... }: {
  services.seatd.enable = true;

  programs.silentSDDM = {
    enable = true;
    theme = "catppuccin-mocha";
  };
}
