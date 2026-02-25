# AGENTS.md — NixOS Configuration Repository

This is a personal NixOS + Home Manager configuration repository using Nix Flakes.
It manages three machines: `anon` (desktop, NVIDIA), `nona` (laptop, AMD), and `vm` (virtual machine).

---

## Repository Structure

```
flake.nix                  # Flake entry point — inputs and outputs
home.nix                   # Home Manager root (imports all home modules)
hosts/<name>/
  configuration.nix        # Per-host NixOS system config
  hardware-configuration.nix
modules/
  home/                    # Home Manager modules (user-level config)
    shells/                # Fish, Zsh, aliases, starship
  system/                  # NixOS system-level modules
    secrets.nix            # Secret loading at eval time from ~/.secrets/
install.sh                 # Bootstrap script
secrets.sh                 # 1Password-based secret fetcher
```

---

## Build Commands

There are no traditional build steps (no `make`, `npm`, `cargo`, etc.). All
operations go through `nix` or `nixos-rebuild`.

### NixOS (full system)

```bash
# Build + activate (the primary workflow)
sudo nixos-rebuild switch --impure --flake ~/nix#anon
sudo nixos-rebuild switch --impure --flake ~/nix#nona
sudo nixos-rebuild switch --impure --flake ~/nix#vm

# Build only — no activation (safe dry-run equivalent)
sudo nixos-rebuild build --impure --flake ~/nix#anon

# Upgrade inputs + switch
sudo nixos-rebuild switch --upgrade --impure --flake ~/nix#anon
```

### Home Manager only

```bash
# Build + activate home config for current host
home-manager switch -b backup --impure --flake ~/nix#$(hostname)

# Build only (no activation)
home-manager build -b backup --impure --flake ~/nix#$(hostname)
```

### Shell aliases (available when logged in)

```bash
nix-switch     # sudo nixos-rebuild switch --impure --flake ~/nix
nix-upgrade    # sudo nixos-rebuild switch --upgrade --impure --flake ~/nix
nix-build      # sudo nixos-rebuild build --impure --flake ~/nix
hm-switch      # home-manager switch -b backup --impure --flake ~/nix#(hostname)
hm-build       # home-manager build -b backup --impure --flake ~/nix#(hostname)
nix-clean      # sudo nix-collect-garbage -d
hm-expire      # home-manager expire-generations -days
```

---

## Validation / "Testing"

This repo has no unit or integration test framework. The equivalent of testing is:

```bash
# Check flake syntax and evaluation without building
nix flake check

# Evaluate a specific flake output attribute
nix eval .#nixosConfigurations.anon.config.system.stateVersion

# Build a single host without switching (fastest safe check)
sudo nixos-rebuild build --impure --flake ~/nix#anon

# Validate a single home module in isolation (evaluate only)
nix eval .#homeConfigurations.anon.config.programs.fish.enable
```

---

## Linting & Formatting

No repo-level linter or formatter is enforced. Community-standard Nix tools:

```bash
# Format Nix files (alejandra — opinionated, widely used in NixOS community)
alejandra .

# Lint Nix files for anti-patterns and dead code
statix check .

# Dead code / unused binding detection
deadnix .
```

None of the above are enforced by CI (there is no CI pipeline).

---

## Secrets

Secrets are loaded at Nix evaluation time from `~/.secrets/` and `~/.ssh/`.
They are **not** committed to the repo. Before building for the first time, run:

```bash
~/nix/secrets.sh   # Fetches secrets from 1Password CLI (requires `op` to be authenticated)
```

If a secret file is missing, evaluation will throw with a descriptive message
(`Secret file not found: <path>`). This is intentional — do not add fallback
empty values that would silently produce broken configs.

---

## Code Style Guidelines

### Module Structure

Every `.nix` file is a function that receives named arguments and returns an
attribute set. Always use `{ ... }:` (or explicit named args) at the top:

```nix
# Preferred: destructure only what you need
{ pkgs, lib, config, hostname, secrets, inputs, ... }:

let
  someValue = "...";
in
{
  programs.foo.enable = true;
}
```

Use a `let...in` block for any local variables or helper functions rather than
inlining complex expressions.

### Naming Conventions

| Scope | Convention | Example |
|---|---|---|
| Files | `kebab-case.nix` | `open-ecc.nix`, `neospleen-nerdfont.nix` |
| Local variables | `camelCase` | `animSpeed`, `mkProfile`, `readSecret` |
| Helper builder functions | `mk` prefix | `mkHost`, `mkProfile` |
| NixOS option paths | `kebab-case` (NixOS convention) | `services.pipewire.enable` |
| Flake attribute names | `camelCase` for locals, `dot.path` for options | `nixosConfigurations` |

### Imports

- Each module is imported **explicitly** — no auto-discovery or directory
  scanning. Add new modules by listing them in `home.nix` or the relevant
  `configuration.nix`.
- Comment out unused imports rather than deleting them when toggling
  alternatives (e.g., `# ./modules/home/kde.nix` vs `./modules/home/hyprland.nix`).
- Keep imports grouped: alternatives commented together, active ones below.

### Per-Machine Variation

Use the `hostname` argument (passed via `specialArgs`) for per-host branching.
Prefer safe attribute access with a default over hard errors:

```nix
# Good — safe default
monitorConfig = monitors.${hostname} or [];

# Good — explicit branch
packages = if hostname == "anon" then [ pkgs.nvidia-container-toolkit ] else [];

# Avoid — throws on unknown host
monitorConfig = monitors.${hostname};
```

Do not create separate files per host for small differences. Use inline
conditionals. Only split into a separate host file when the divergence is large
(as with `hardware-configuration.nix`).

### Package Lists

Use `with pkgs;` only for list-heavy blocks (e.g., `packages.nix`). Avoid it
in module body — prefer `pkgs.foo` for clarity:

```nix
# Good for long package lists
home.packages = with pkgs; [
  ripgrep
  fd
  jq
];

# Good for single references in config
programs.git.package = pkgs.git;
```

### Builtins vs lib

- Use `builtins.*` directly for: `readFile`, `pathExists`, `toJSON`, `fromJSON`,
  `toString`, `concatLists`, `genList`, `pathExists`.
- Use `lib.*` for higher-level operations: `lib.optionals`, `lib.genAttrs`,
  `lib.hm.dag.entryAfter`, `lib.mkIf`, `lib.mkMerge`.
- Do not reach for `lib` when a plain `builtins` function will do.

### Secrets & Sensitive Values

- Never hardcode secrets, tokens, usernames, or company names in `.nix` files.
- Always access them through the `secrets` attrset (e.g., `secrets.workName`,
  `secrets.anthropicKey`).
- Add new secrets to `modules/system/secrets.nix` using the `readSecret`
  helper, and add the corresponding file to `secrets.sh` for provisioning.

### Strings & Multiline

Use `''...''` (double-single-quote) strings for multiline content and shell
scripts. Use `"..."` for single-line strings with interpolation.

```nix
# Multiline (indentation is stripped automatically)
script = ''
  #!/usr/bin/env bash
  set -euo pipefail
  echo "Hello, ${name}"
'';

# Single line
greeting = "Hello, ${name}";
```

### Error Handling

- Bash scripts (`install.sh`, `secrets.sh`) must use `set -euo pipefail`.
- In Nix, use `builtins.pathExists` before `builtins.readFile` and `throw`
  with a descriptive message on failure — never silently return an empty string.
- Evaluation-time errors are the correct signal for missing required secrets.

### Formatting Conventions

- Indent with **2 spaces** (standard Nix community style).
- Opening braces on the same line; closing braces on their own line.
- Trailing commas in multi-line lists and attrsets.
- Align `=` signs within a single attrset block when it improves readability.
- Leave one blank line between top-level attributes in a module body.
