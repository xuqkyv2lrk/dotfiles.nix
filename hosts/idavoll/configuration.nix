{ pkgs, ... }:
let
  user = "s1uyx";
  home = "/home/${user}";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/es-de-console.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  zramSwap = { enable = true; algorithm = "zstd"; };

  networking.hostName = "idavoll";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  services.esde-console = {
    enable = true;
    inherit user;
    saveSync.hub = {
      id = "EVXONQU-3BGDCFM-EDTD3JA-DJIHZLM-WSK33FK-6C3PAJH-DCUUOP7-24BOSAL";
      address = "tcp://192.168.22.201:22000";
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # The shell is configured system-wide; an empty .zshrc stops zsh-newuser-install
  systemd.tmpfiles.rules = [ "f ${home}/.zshrc 0644 ${user} users -" ];

  nixpkgs.config.allowUnfree = true;

  users.users.${user} = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell        = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBlLgOdppXfl7Btvz4hx59JTp7ZNdPRklL+2eOlVOZMy"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    histSize = 10000;
    setOptions = [ "SHARE_HISTORY" "HIST_IGNORE_DUPS" "HIST_IGNORE_SPACE" ];
    # Catppuccin Mocha: blue user@host, mauve path, green prompt
    promptInit = ''
      PROMPT='%F{#89b4fa}%n@%m%f %F{#cba6f7}%~%f %F{#a6e3a1}❯%f '
    '';
    # Inputs are updated and pushed from the workstations, so these pull rather than
    # commit; idavoll has no push access or signing key
    shellAliases = {
      nrs = "git -C ${home}/.dotfiles.nix pull --ff-only && sudo nixos-rebuild switch --flake '${home}/.dotfiles.nix#idavoll'";
      nru = "git -C ${home}/.dotfiles.nix pull --ff-only && sudo nixos-rebuild boot --flake '${home}/.dotfiles.nix#idavoll'";
    };
  };

  environment.systemPackages = with pkgs; [ vim git rsync pciutils ];

  # First NixOS version installed on this machine; do not change.
  system.stateVersion = "26.11";
}
