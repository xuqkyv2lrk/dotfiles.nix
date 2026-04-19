<div align="center">
<img src="https://brand.nixos.org/logos/nixos-logo-default-gradient-white-regular-vertical-recommended.svg" alt="dotfiles.nix" width="250px" />
<h3>dotfiles.nix</h3>
<p>NixOS system configurations managed with Nix flakes and Home Manager.</p>
<p>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-BSD%203--Clause-blue.svg" alt="License" /></a>
  <a href="https://gitlab.com/wd2nf8gqct/dotfiles.nix"><img src="https://img.shields.io/badge/GitLab-Main-orange.svg?logo=gitlab" alt="GitLab" /></a>
  <a href="https://github.com/xuqkyv2lrk/dotfiles.nix"><img src="https://img.shields.io/badge/GitHub-Mirror-black.svg?logo=github" alt="GitHub Mirror" /></a>
  <a href="https://codeberg.org/iw8knmadd5/dotfiles.nix"><img src="https://img.shields.io/badge/Codeberg-Mirror-2185D0.svg?logo=codeberg" alt="Codeberg Mirror" /></a>
</p>
<p>
  <a href="https://nixos.org"><img src="https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white&style=flat" alt="NixOS" /></a>
</p>
</div>

## Usage

All install paths start from the **NixOS installer ISO**. Partition, format, and mount
the disk first, then follow the [base installation guide](#base-installation-guide) —
it covers both new machines and reinstalls.

**Day-to-day config changes** (already running system, not a reinstall):

```bash
sudo nixos-rebuild switch --flake "${HOME}/.dotfiles.nix#$(hostname)"
```

---

## Repository layout

```
.
├── flake.nix                          # entry point — inputs and outputs
├── flake.lock                         # pinned input revisions
├── hosts/
│   └── xiuhcoatl/
│       ├── configuration.nix          # system-level config
│       └── hardware-configuration.nix # generated, do not edit manually
├── home/
│   ├── modules/
│   │   ├── base.nix       # packages, dotfiles.core symlinks, activation scripts
│   │   ├── noctalia.nix   # quickshell + runtime deps (shared by all WMs)
│   │   ├── hyprland.nix   # hyprland tools + dotfiles.di symlinks
│   │   ├── niri.nix       # niri tools + dotfiles.di symlinks
│   │   ├── sway.nix       # sway tools + dotfiles.di symlinks
│   │   ├── gnome.nix      # GNOME dconf settings + extension packages
│   │   └── paperwm.nix    # optional PaperWM add-on for GNOME
│   └── <user>.nix         # user identity + module imports
└── modules/
    └── nixos/
        ├── noctalia.nix   # system hooks (lock + wifi resume); auto-activates when any HM user has noctalia
        ├── laptop.nix     # shared laptop power settings
        └── hardware/      # reusable per-hardware NixOS modules
```

Each user config (`home/<user>.nix`) declares the user identity and imports exactly the
modules it needs. A headless server imports only `base.nix`. A desktop machine adds one
DE module, plus `noctalia.nix` if using a Wayland compositor (Hyprland, Niri, Sway).
GNOME manages its own shell, so `noctalia.nix` is not used with `gnome.nix`.
Only one DE module should be imported per user — configs are DE-specific and will
conflict if combined. `paperwm.nix` is the sole exception: it is an optional add-on
imported alongside `gnome.nix` when PaperWM tiling is wanted.

## Relationship to other dotfiles repos

| Repo | Purpose |
|------|---------|
| [dotfiles.core](https://gitlab.com/wd2nf8gqct/dotfiles.core) | Program configs (zsh, tmux, vim, etc.) — distro-agnostic |
| [dotfiles.di](https://gitlab.com/wd2nf8gqct/dotfiles.di) | Desktop interface (Hyprland, Niri, etc.) |
| **dotfiles.nix** (this repo) | NixOS system config + Home Manager |

`dotfiles.core` is the single source of truth for program configurations and works the
same across all distros — Home Manager handles package installation while the actual
configs are cloned from `dotfiles.core` and symlinked via the activation scripts in
`home/modules/base.nix`. `dotfiles.di` uses git submodules and must always be cloned
with `--recurse-submodules`.

---

## Base installation guide

For more in-depth coverage of the installation process, see the
[official NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation).

### 1. Boot the NixOS installer

Download the minimal ISO from [nixos.org](https://nixos.org/download) and boot from it.
Become root:

```bash
sudo -i
```

### 2. Partition the disk

Identify your target disk:

```bash
lsblk
```

Partition with `parted` (GPT). Replace `/dev/sda` with your actual disk:

```bash
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 1GiB  # 1GiB recommended for NixOS: each generation stores its own kernel + initrd here
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 1GiB 100%
```

### 3. Format the partitions

Labels let us reference partitions by name rather than device path, which is stable across
reboots and hardware changes.

```bash
mkfs.fat -F 32 -n BOOT /dev/sda1
mkfs.btrfs -L nixos /dev/sda2
```

Partitions are now addressable as `/dev/disk/by-label/BOOT` and `/dev/disk/by-label/nixos`.

### 4. Create btrfs subvolumes

Mount the root btrfs volume temporarily to create subvolumes:

```bash
mount /dev/disk/by-label/nixos /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@snapshots

umount /mnt
```

### 5. Mount with correct options

```bash
mount -o noatime,compress=zstd,subvol=@ /dev/disk/by-label/nixos /mnt

mkdir -p /mnt/{boot,home,nix,var/log,.snapshots}

mount /dev/disk/by-label/BOOT /mnt/boot
mount -o noatime,compress=zstd,subvol=@home      /dev/disk/by-label/nixos /mnt/home
mount -o noatime,compress=zstd,subvol=@nix       /dev/disk/by-label/nixos /mnt/nix
mount -o noatime,compress=zstd,subvol=@log       /dev/disk/by-label/nixos /mnt/var/log
mount -o noatime,compress=zstd,subvol=@snapshots /dev/disk/by-label/nixos /mnt/.snapshots
```

`noatime` avoids unnecessary write amplification on btrfs. `compress=zstd` gives transparent
compression with a good speed/ratio tradeoff.

### 6. Generate hardware config

```bash
nixos-generate-config --root /mnt
```

This reads the active mounts and writes `hardware-configuration.nix` under
`/mnt/etc/nixos/`. The generated btrfs entries will include the subvolume but
`nixos-generate-config` does not reliably carry over all mount options — manually
add `"noatime"` and `"compress=zstd"` to each btrfs `options` list before continuing.

Each btrfs `fileSystems` entry should look like this:

```nix
fileSystems."/" = {
  device = "/dev/disk/by-label/nixos";
  fsType = "btrfs";
  options = [ "subvol=@" "noatime" "compress=zstd" ];
};
```

Open the file and verify each btrfs mount has those options:

```bash
vim /mnt/etc/nixos/hardware-configuration.nix
```

### 7. Install

**New machine** (hostname not yet declared in this repo) — use
[dotfiles.bootstrap](https://gitlab.com/wd2nf8gqct/dotfiles.bootstrap), which
scaffolds `hosts/<hostname>/configuration.nix`, wires it into `flake.nix`, runs
`nixos-install`, and copies the repo into the installed system:

```bash
git clone https://gitlab.com/wd2nf8gqct/dotfiles.bootstrap.git /tmp/dotfiles.bootstrap
cd /tmp/dotfiles.bootstrap
./bootstrap.sh
```

**Reinstall on an existing host** (hostname already declared in `flake.nix`) — skip
bootstrap and install directly:

```bash
git clone https://gitlab.com/wd2nf8gqct/dotfiles.nix.git /tmp/dotfiles.nix
cp /mnt/etc/nixos/hardware-configuration.nix "/tmp/dotfiles.nix/hosts/$(hostname)/hardware-configuration.nix"
nixos-install --flake "/tmp/dotfiles.nix#$(hostname)"
```

### 8. Reboot

```bash
reboot
```

### 9. First boot

`home-manager-<user>.service` runs automatically at first boot. Both dotfiles repos
are pre-cloned during installation, so activation just writes symlinks — no network
dependency at boot.

### 10. Switch remotes to SSH

The repos were cloned over HTTPS during install. To push via SSH, run the helper
(available in your shell after first boot):

```bash
dotfiles-use-ssh
```

Enter your SSH remote prefix when prompted — `git@gitlab.com` or an alias from your SSH
config (e.g. `gitlab`). It updates all dotfiles repos and submodules in one shot.

### 11. Commit the hardware config

The repo was copied into `~/.dotfiles.nix` by bootstrap. Commit the hardware config and
push so the repo reflects the real hardware:

```bash
cd ~/.dotfiles.nix
git add "hosts/$(hostname)/hardware-configuration.nix"
git commit -m "chore($(hostname)): add hardware config"
git push
```

All future rebuilds run from here:

```bash
sudo nixos-rebuild switch --flake "${HOME}/.dotfiles.nix#$(hostname)"
```

> [!NOTE]
> zsh interprets `#` as a comment character. Always quote the flake argument as shown above.

---

## Adding a new machine

1. Create `hosts/<hostname>/configuration.nix` — enable the compositor or GNOME, declare the user, import the appropriate hardware module.
2. Run `nixos-generate-config` during install and commit `hardware-configuration.nix`.
3. Create `home/<user>.nix` with the right module imports:
   - Wayland compositor: `base.nix` + `noctalia.nix` + one of `hyprland.nix` / `niri.nix` / `sway.nix`
   - GNOME: `base.nix` + `gnome.nix` (+ `paperwm.nix` if using PaperWM)
4. Wire it in `flake.nix` under `nixosConfigurations.<hostname>`, including `./modules/nixos/noctalia.nix` in the modules list. It is a no-op on hosts without a noctalia user.

---

## Day-to-day workflow

Rebuild and switch to the current config:

```bash
sudo nixos-rebuild switch --flake "${HOME}/.dotfiles.nix#$(hostname)"
```

Update all flake inputs to their latest revisions:

```bash
cd ~/.dotfiles.nix
nix flake update "${HOME}/.dotfiles.nix"
sudo nixos-rebuild switch --flake ".#$(hostname)"
```

Roll back if something breaks:

```bash
nixos-rebuild switch --rollback
```

Or pick an older generation from the boot menu at startup.

## Garbage collection

Old generations and unused store paths are collected automatically (weekly, keeping 7 days).
To collect manually:

```bash
nix-collect-garbage -d
```
