{ config, pkgs, ... }:
{
  home.username = "lqnw3c";
  home.homeDirectory = "/home/lqnw3c";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # browsers & mail
    firefox
    thunderbird

    # terminal emulator
    foot

    # password managers
    bitwarden-desktop
    _1password-cli
    _1password-gui

    # editors
    emacs

    # media
    mpv
    cava
    mpc_cli
    ncmpcpp
    ncspot
    yt-dlp
    ffmpeg
    imagemagick

    # cli utilities
    bat
    bc
    btop
    cloudflared
    curl
    delta
    dmidecode
    eza
    fastfetch
    fd
    jq
    ripgrep
    rsync
    unzip
    wget
    wireguard-tools
    wl-clipboard
    yazi
    yq-go

    # development
    cmake
    gcc
    go
    graphviz
    kubectl
    meson
    nodejs
    openssl
    openssl.dev
    pandoc
    python3
    shellcheck

    # virtualisation (GUI tools — services enabled in configuration.nix)
    virt-manager
    virt-viewer
  ];

  # --- Program modules ---

  programs.zsh = {
    enable = true;
  };

  programs.tmux = {
    enable = true;
  };

  programs.vim = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # --- User services ---

  services.mpd = {
    enable = true;
    musicDirectory = "~/music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
    '';
  };
}
