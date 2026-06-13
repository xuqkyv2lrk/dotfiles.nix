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

  home.activation.doomSync = lib.hm.dag.entryAfter ["writeBoundary"] ''
    DOOM_BIN="${config.home.homeDirectory}/.emacs.d/bin/doom"
    DOOM_LOCAL="${config.home.homeDirectory}/.emacs.d/.local"
    if [ -x "$DOOM_BIN" ] && [ ! -d "$DOOM_LOCAL" ]; then
      $DRY_RUN_CMD "$DOOM_BIN" sync || true
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
    ungoogled-chromium
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

    # media
    mpv
    cava
    mpc
    ncmpcpp
    ncspot
    yt-dlp
    ffmpeg
    ffmpeg-lh
    imagemagick
    jellyfin-desktop
    feishin

    # rom management
    igir
    mame-tools

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
    file
    jq
    p7zip
    zstd
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
    manix
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
    opentofu
    sops
    talosctl
    terraform
    terraform-ls

    # shell utilities
    atuin

    dyff
    oh-my-posh

    # virtualisation (GUI tools — services enabled in configuration.nix)
    virt-manager
    virt-viewer
  ];

  home.activation.createWorkingDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for dir in \
      "${config.home.homeDirectory}/bin" \
      "${config.home.homeDirectory}/notes/tome" \
      "${config.home.homeDirectory}/work/priming" \
      "${config.home.homeDirectory}/work/projects" \
      "${config.home.homeDirectory}/work/sandbox"; do
      $DRY_RUN_CMD mkdir -p "$dir"
    done
  '';

  home.activation.vimPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PLUG_VIM="${config.home.homeDirectory}/.vim/autoload/plug.vim"
    PLUG_DIR="${config.home.homeDirectory}/.vim/plugged"
    if [ ! -f "$PLUG_VIM" ]; then
      $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fLo "$PLUG_VIM" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    if [ ! -d "$PLUG_DIR" ]; then
      $DRY_RUN_CMD ${pkgs.vim}/bin/vim +'PlugInstall --sync' +qa < /dev/null || true
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

  home.activation.yaziPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    YAZI_PLUGINS="${config.home.homeDirectory}/.config/yazi/plugins"
    YAZI_PKG="${config.home.homeDirectory}/.config/yazi/package.toml"
    if [ ! -d "$YAZI_PLUGINS" ] && [ -f "$YAZI_PKG" ]; then
      $DRY_RUN_CMD ${pkgs.yazi}/bin/ya pkg install || true
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

  programs.mise.enable = true;

  programs.fzf.enable = true;
  programs.zoxide.enable = true;

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    GDK_BACKEND = "wayland";
  };

  # home.sessionVariables only reaches the login shell (hm-session-vars.sh).
  # Wayland-forcing vars must also live in environment.d so systemd user units
  # and all graphical apps (launched by niri, not the shell) inherit them.
  xdg.configFile."environment.d/91-wayland-session.conf".text = ''
    GDK_BACKEND=wayland
    NIXOS_OZONE_WL=1
    MOZ_ENABLE_WAYLAND=1
  '';

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

  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    settings = {
      program_options.file_manager = "nautilus";
      notifications = {
        device_added = false;
        device_removed = false;
      };
    };
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
