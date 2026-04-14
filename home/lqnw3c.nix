{ config, pkgs, lib, ... }:
let
  dotfilesCore = "${config.home.homeDirectory}/.dotfiles.core";
  lnCore = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesCore}/${path}";
in
{
  home.username = "lqnw3c";
  home.homeDirectory = "/home/lqnw3c";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Clone dotfiles repos on first activation, before symlinks are created
  home.activation.cloneDotfilesCore = lib.hm.dag.entryBefore ["writeBoundary"] ''
    if [ ! -d "${config.home.homeDirectory}/.dotfiles.core" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://gitlab.com/wd2nf8gqct/dotfiles.core.git \
        "${config.home.homeDirectory}/.dotfiles.core"
    fi
  '';

  home.activation.cloneDotfilesDi = lib.hm.dag.entryBefore ["writeBoundary"] ''
    if [ ! -d "${config.home.homeDirectory}/.dotfiles.di" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://gitlab.com/wd2nf8gqct/dotfiles.di.git \
        "${config.home.homeDirectory}/.dotfiles.di"
    fi
  '';

  # dotfiles.core symlinks
  # mkOutOfStoreSymlink points directly to files on disk — edits are live, no rebuild needed
  xdg.configFile."bat".source      = lnCore "bat/.config/bat";
  xdg.configFile."btop".source     = lnCore "btop/.config/btop";
  xdg.configFile."cava".source     = lnCore "cava/.config/cava";
  xdg.configFile."delta".source    = lnCore "delta/.config/delta";
  xdg.configFile."fastfetch".source = lnCore "fastfetch/.config/fastfetch";
  xdg.configFile."foot".source     = lnCore "foot/.config/foot";
  xdg.configFile."mpd".source      = lnCore "mpd/.config/mpd";
  xdg.configFile."ncmpcpp".source  = lnCore "ncmpcpp/.config/ncmpcpp";
  xdg.configFile."ncspot".source   = lnCore "ncspot/.config/ncspot";
  xdg.configFile."ohmyposh".source = lnCore "ohmyposh/.config/ohmyposh";
  xdg.configFile."yazi".source     = lnCore "yazi/.config/yazi";
  xdg.configFile."zsh".source      = lnCore "zsh/.config/zsh";

  home.file.".zshrc".source    = lnCore "zsh/.zshrc";
  home.file.".zshenv".source   = lnCore "zsh/.zshenv";
  home.file.".tmux.conf".source = lnCore "tmux/.tmux.conf";
  home.file.".tmux".source     = lnCore "tmux/.tmux";
  home.file.".vimrc".source    = lnCore "vim/.vimrc";
  home.file.".vim".source      = lnCore "vim/.vim";
  home.file.".doom.d".source   = lnCore "doom/.doom.d";
  home.file.".gitconfig".source = lnCore "gitconfig/.gitconfig";

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
    mpc
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

  # Program modules
  # zsh integrations are handled by dotfiles.core zshrc — no enableZshIntegration needed
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf.enable = true;
  programs.zoxide.enable = true;

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
