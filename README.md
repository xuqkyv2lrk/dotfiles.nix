# dotfiles.nix

NixOS system configurations managed with Nix flakes and Home Manager.

## Repository layout

```
.
├── flake.nix                          # entry point — inputs and outputs
├── flake.lock                         # pinned input revisions
├── hosts/
│   └── xiuhcoatl/
│       ├── configuration.nix          # system-level config
│       └── hardware-configuration.nix # generated, do not edit manually
└── home/
    └── lqnw3c.nix                     # Home Manager user config
```

## Relationship to other dotfiles repos

| Repo | Purpose |
|------|---------|
| [dotfiles.core](https://gitlab.com/wd2nf8gqct/dotfiles.core) | Program configs (zsh, tmux, vim, etc.) — distro-agnostic |
| [dotfiles.di](https://gitlab.com/wd2nf8gqct/dotfiles.di) | Desktop interface (Hyprland, Niri, etc.) |
| **dotfiles.nix** (this repo) | NixOS system config + Home Manager |

`dotfiles.core` is the single source of truth for program configurations. It is cloned and
managed on NixOS exactly as on Arch — Home Manager handles package installation, while
program configs gradually migrate into native `programs.*` modules in `home/lqnw3c.nix`.

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
parted /dev/sda -- mkpart ESP fat32 1MiB 1GiB
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

### 6. Generate initial config and install

```bash
nixos-generate-config --root /mnt
```

This writes `/mnt/etc/nixos/configuration.nix` and `hardware-configuration.nix`. Edit the
generated `configuration.nix` minimally to enable networking and set a root password, then
install:

```bash
nixos-install
reboot
```

### 7. Bootstrap from this repo

After first boot, log in as root and enable flakes temporarily:

```bash
nix-env -iA nixos.git
```

Clone the repo:

```bash
git clone https://gitlab.com/wd2nf8gqct/dotfiles.nix.git /etc/dotfiles.nix
cd /etc/dotfiles.nix
```

Copy the generated hardware config into the repo:

```bash
cp /etc/nixos/hardware-configuration.nix hosts/xiuhcoatl/hardware-configuration.nix
```

Replace the placeholder `configuration.nix` with your actual one (or merge the two), then
apply the full flake configuration:

```bash
nixos-rebuild switch --flake .#xiuhcoatl
```

### 8. zram

zram is already declared in `hosts/xiuhcoatl/configuration.nix`:

```nix
zramSwap = {
  enable = true;
  algorithm = "zstd";
};
```

This creates a compressed in-memory swap device. The default size is 50% of physical RAM.
To adjust, add `memoryPercent = 25;` (or whatever fraction suits your workload).

---

## Day-to-day workflow

Rebuild and switch to the current config:

```bash
nixos-rebuild switch --flake /etc/dotfiles.nix#xiuhcoatl
```

Update all flake inputs to their latest revisions:

```bash
nix flake update
nixos-rebuild switch --flake .#xiuhcoatl
```

Roll back if something breaks:

```bash
nixos-rebuild switch --rollback
```

Or pick an older generation from the boot menu at startup.

## Applying Home Manager changes only

If only `home/lqnw3c.nix` changed and a full system rebuild is overkill:

```bash
home-manager switch --flake /etc/dotfiles.nix#lqnw3c
```

## Garbage collection

Old generations and unused store paths are collected automatically (weekly, keeping 14 days).
To collect manually:

```bash
nix-collect-garbage -d
```
