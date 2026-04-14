# Home Manager configuration for lqnw3c on xiuhcoatl.
#
# Strategy: start by declaring packages here and managing program options
# natively through Home Manager modules. Over time, configs that currently
# live in dotfiles.core will migrate here as proper `programs.*` blocks.
#
# For configs not yet ported, keep using dotfiles.core with stow on this
# machine the same way you do on Arch — Home Manager and stow coexist fine.
{ config, pkgs, ... }:
{
  home.username = "lqnw3c";
  home.homeDirectory = "/home/lqnw3c";
  home.stateVersion = "25.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Packages not managed via program modules below
  home.packages = with pkgs; [
    bat
    btop
    cava
    delta
    fastfetch
    mpd
    ncmpcpp
    ncspot
    yazi
  ];

  # --- Program modules (native Nix way) ---
  # These replace the corresponding dotfiles.core configs as you migrate.

  programs.zsh = {
    enable = true;
    # initExtra, shellAliases, etc. go here eventually
  };

  programs.tmux = {
    enable = true;
    # extraConfig goes here eventually
  };

  programs.vim = {
    enable = true;
    # extraConfig goes here eventually
  };
}
