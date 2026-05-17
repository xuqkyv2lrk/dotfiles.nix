{ config, pkgs, lib, ... }:
let
  dotfilesCore = "${config.home.homeDirectory}/.dotfiles.core";
  lnCore = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesCore}/${path}";
in
{
  programs.home-manager.enable = true;

  # Clone dotfiles repos on first activation, before symlinks are created
  home.activation.cloneDotfilesCore = lib.hm.dag.entryBefore ["writeBoundary"] ''
    if [ ! -d "${config.home.homeDirectory}/.dotfiles.core" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://gitlab.com/wd2nf8gqct/dotfiles.core.git \
        "${config.home.homeDirectory}/.dotfiles.core"
    fi
  '';

  home.activation.cloneDoomEmacs = lib.hm.dag.entryBefore ["writeBoundary"] ''
    if [ ! -d "${config.home.homeDirectory}/.emacs.d" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone --depth 1 \
        https://github.com/doomemacs/doomemacs \
        "${config.home.homeDirectory}/.emacs.d"
    fi
  '';

  home.activation.cloneDotfilesDi = lib.hm.dag.entryBefore ["writeBoundary"] ''
    if [ ! -d "${config.home.homeDirectory}/.dotfiles.di" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone --recurse-submodules \
        https://gitlab.com/wd2nf8gqct/dotfiles.di.git \
        "${config.home.homeDirectory}/.dotfiles.di"
    fi
  '';

  home.activation.cloneUtilityScripts = lib.hm.dag.entryBefore ["writeBoundary"] ''
    if [ ! -d "${config.home.homeDirectory}/utility-scripts" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone \
        https://gitlab.com/wd2nf8gqct/utility-scripts.git \
        "${config.home.homeDirectory}/utility-scripts"
      $DRY_RUN_CMD bash "${config.home.homeDirectory}/utility-scripts/setup.sh" || true
    fi
  '';

  # dotfiles.core symlinks
  # mkOutOfStoreSymlink points directly to files on disk — edits are live, no rebuild needed
  xdg.configFile."bat".source       = lnCore "bat/.config/bat";
  xdg.configFile."btop".source      = lnCore "btop/.config/btop";
  xdg.configFile."cava".source      = lnCore "cava/.config/cava";
  xdg.configFile."delta".source     = lnCore "delta/.config/delta";
  xdg.configFile."fastfetch".source = lnCore "fastfetch/.config/fastfetch";
  xdg.configFile."foot".source      = lnCore "foot/.config/foot";
  xdg.configFile."mpd".source       = lnCore "mpd/.config/mpd";
  xdg.configFile."ncmpcpp".source   = lnCore "ncmpcpp/.config/ncmpcpp";
  xdg.configFile."ncspot".source    = lnCore "ncspot/.config/ncspot";
  xdg.configFile."ohmyposh".source  = lnCore "ohmyposh/.config/ohmyposh";
  xdg.configFile."yazi".source      = lnCore "yazi/.config/yazi";
  xdg.configFile."zsh".source       = lnCore "zsh/.config/zsh";

  # Allow unfree packages in nix-shell and other standalone nix commands
  home.file.".config/nixpkgs/config.nix".text = "{ allowUnfree = true; }";

  home.file.".zshrc".source     = lnCore "zsh/.zshrc";
  home.file.".zshenv".source    = lnCore "zsh/.zshenv";
  home.file.".tmux.conf".source = lnCore "tmux/.tmux.conf";
  home.file.".tmux".source      = lnCore "tmux/.tmux";
  home.file.".vimrc".source     = lnCore "vim/.vimrc";
  home.file.".vim".source       = lnCore "vim/.vim";
  home.file.".doom.d".source    = lnCore "doom/.doom.d";
  home.file.".gitconfig".source = lnCore "gitconfig/.gitconfig";
  home.file.".claude".source    = lnCore "claude/.claude";

  home.packages = with pkgs; [
    # unfree — audit list; each package requires allowUnfree in nixpkgs config
    claude-code
    _1password-cli
    _1password-gui
    steam
    stremio-linux-shell
    plex-desktop
    # (nvidia drivers are unfree but managed in modules/nixos/hardware/nvidia.nix)

    # genai
    gemini-cli

    # browsers & mail
    firefox
    thunderbird

    # communication
    signal-desktop

    # terminal emulator
    foot

    # password managers
    bitwarden-desktop

    # editors
    emacs
    vim
    tmux

    # hardware configuration
    betaflight-configurator

    # media
    mpv
    cava
    mpc
    ncmpcpp
    ncspot
    yt-dlp
    ffmpeg
    imagemagick
    jellyfin-desktop
    feishin

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
    gnupg
    pinentry-tty
    cmake
    gcc
    gnumake
    go
    graphviz
    kubectl
    meson
    nodejs
    openssl
    openssl.dev
    pandoc
    python3
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer
    shellcheck
    exercism
    bind
    uv

    # devops / infra
    awscli2
    fluxcd
    kubernetes-helm
    sops
    talosctl
    terraform

    # shell utilities
    atuin
    diff-so-fancy
    dyff
    oh-my-posh

    # virtualisation (GUI tools — services enabled in configuration.nix)
    virt-manager
    virt-viewer
  ];

  home.activation.vimPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PLUG_VIM="${config.home.homeDirectory}/.vim/autoload/plug.vim"
    if [ ! -f "$PLUG_VIM" ]; then
      $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fLo "$PLUG_VIM" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
  '';

  home.activation.tmuxPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
    TPM_DIR="${config.home.homeDirectory}/.tmux/plugins/tpm"
    if [ ! -d "$TPM_DIR" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
      TMUX_PLUGIN_MANAGER_PATH="${config.home.homeDirectory}/.tmux/plugins" \
        $DRY_RUN_CMD bash "$TPM_DIR/scripts/install_plugins.sh" || true
    fi
  '';

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-tty;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf.enable = true;
  programs.zoxide.enable = true;

  # Tell xdg-desktop-portal (and apps like Firefox) to use dark mode
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # Unset DISPLAY so jellyfin-desktop skips DisplayManagerX11 initialization,
  # which crashes on wake-from-sleep when the XWayland connection is broken.
  xdg.desktopEntries."org.jellyfin.JellyfinDesktop" = {
    name = "Jellyfin";
    comment = "Desktop client for Jellyfin";
    exec = "env -u DISPLAY jellyfin-desktop";
    icon = "org.jellyfin.JellyfinDesktop";
    terminal = false;
    categories = [ "AudioVideo" "Video" "Player" "TV" ];
  };

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
