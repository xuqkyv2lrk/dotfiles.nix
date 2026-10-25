{ config, ... }:
let
  dotfilesDi = "${config.home.homeDirectory}/.dotfiles.di";
  lnDi = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDi}/${path}";
in
{
  # The compositor itself is enabled at system level via programs.umbriel.enable.
  # Shared session packages (nautilus, portals, theming) come from niri.nix.

  # dotfiles.di umbriel symlinks
  xdg.configFile."umbriel".source = lnDi "umbriel/umbriel/.config/umbriel";
}
