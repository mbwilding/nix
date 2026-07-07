# Nix Config - Agent Guide

## Structure

Dendritic pattern using `import-tree` to auto-load all `.nix` files under `modules/`.
`flake.nix` has a single outputs line; all real config lives in modules.

```
modules/
  nix/            # flake-parts wiring, secrets, home-manager tool
  hosts/          # per-host configs (anon, nona, wsl, droid, vm)
  features/       # reusable modules grouped by category
    applications/ # app configs
    configs/      # shell, files, package-managers, etc.
    core/         # development, packages
    desktops/     # hyprland, niri, kde, wayland-session
    drivers/      # gpu-amd, gpu-nvidia, solaar, streamcontroller
    networking/   # mounts, proxy, wireguard-nona
    system/       # audio, fonts, secrets, system-base, system-default, ucodenix
  users/          # mbwilding, droid
```

## Directory name suffixes

`[N]` = NixOS module only
`[n]` = home-manager module only
`[Nn]` = both NixOS and home-manager modules

## Applying config

```bash
# NixOS rebuild (used by install.sh)
sudo nixos-rebuild switch --impure --flake ~/nix#<hostname>

# Standalone home-manager
home-manager switch --impure --flake ~/nix#<hostname>

# nix-on-droid
nix-on-droid switch --flake ~/nix#droid
```

`install.sh` wraps the NixOS rebuild and accepts the hostname as an argument.

## Secrets

All secrets are read at eval time from `~/.secrets/` and `~/.ssh/` via `modules/nix/_secrets.nix`.
Run `scripts/secrets.sh` before first build; it uses 1Password CLI to populate those files.
Secrets are never in the repo; missing secret files cause eval failures.

## Three nixpkgs channels

| Arg | Flake input | Use |
|---|---|---|
| `pkgs` | `nixpkgs` (unstable) | default |
| `pkgsMaster` | `nixpkgs-master` | bleeding-edge packages |
| `pkgsStable` | `nixpkgs-stable` (26.05) | stability-sensitive packages |

`pkgsMaster` and `pkgsStable` are injected via `_module.args` in `lib.nix`.

## Binary caches

Configured in `modules/nix/flake-parts/lib.nix` via `sharedNixSettings`:

| Cache | Key attr |
|---|---|
| `https://attic.xuyh0120.win/lantian` | `lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=` |
| `https://noctalia.cachix.org` | `noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=` |

`noctalia` and `niri` inputs deliberately omit `nixpkgs.follows` to preserve cache hits.

## Hosts

| Host | Type | Notes |
|---|---|---|
| `anon` | NixOS desktop | Nvidia GPU, CachyOS kernel (bore-lto-zen4), Hyprland |
| `nona` | NixOS laptop | AMD GPU, CachyOS kernel, Hyprland, Dvorak, wireguard |
| `wsl` | NixOS WSL | Minimal, Docker, no fish at system level |
| `vm` | NixOS VM | Minimal |
| `droid` | nix-on-droid | aarch64, `nixOnDroidConfigurations` not `nixosConfigurations` |

## Manually updated packages

These files require version/hash updates by hand (not handled by `nix flake update`):

- `modules/features/applications/yabridge [n]/yabridge.nix`
- `modules/features/configs/mcp [n]/_nvim-mcp.nix`
- `modules/features/core/development [Nn]/_gh-actions-language-server.nix`
- `modules/features/core/development [Nn]/_vscode-bash-debug.nix`
- `modules/features/system/fonts [N]/_microsoft-fonts.nix`
- `modules/features/system/fonts [N]/_neospleen-nerdfont.nix`
- `modules/features/system/fonts [N]/_neospleen.nix`
- `modules/features/core/packages [n]/_dtctl.nix`
- `modules/features/core/packages [n]/_github-copilot.nix`
- `modules/features/core/packages [n]/_open-ecc.nix`
- `modules/features/core/packages [n]/_power-platform-toolbox.nix`
- `modules/features/core/packages [n]/_steam-achievement-manager.nix`

## Key settings (system-default)

- Timezone: `Australia/Perth`, locale: `en_AU.UTF-8`
- Nix store auto-optimise enabled, weekly GC (7d retention)
- `download-buffer-size` set to 5 GiB
- `allowUnfree = true`, `pnpm-10.34.0` permitted insecure
- `result` symlinks and `.idea/` are gitignored; wallpapers tracked as binary
