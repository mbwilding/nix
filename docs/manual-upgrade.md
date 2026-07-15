# Manually Upgradable Packages

Files that require manual version/hash updates (not handled by `nix flake update`).

## Workflow

1. For each file below, run its "check latest" command to compare against the `version`/`rev` currently in the file.
2. If newer, fetch the new SRI hash(es) with:
   ```
   nix store prefetch-file --json "<url>" | jq -r '.hash'
   ```
   Do this for every platform entry in the file (`sources.<system>.url`), not just one.
3. Edit the `version` (and `rev`, if GitHub-commit-pinned) and every corresponding `hash`.
4. Verify it actually builds (paths contain spaces/`[n]` so quote them, and use the
   `/. + "..."` trick to avoid Nix path-literal syntax errors on `[`/`]`/spaces):
   ```
   nix build --impure --expr '
     let pkgs = import <nixpkgs> {};
     in pkgs.callPackage (/. + "/home/mbwilding/nix/modules/features/.../_foo.nix") { }
   ' --no-link --print-out-paths
   ```
   Linux-only packages (e.g. github-copilot's FHS wrapper) will only actually build on
   Linux; on other platforms just trust the hash fetch.
5. `nix flake check` currently fails on an unrelated pre-existing swap-module issue
   (`total-mem-kib.drv` / `system.build.toplevel` for `nixosConfigurations.anon`) — don't
   let that block you, use the direct `nix build --impure --expr` check above instead.
6. Update this file's per-entry "last checked" info isn't tracked here; just rely on
   the check commands below being cheap enough to rerun every time.

## Checking latest upstream version, by source type

- **GitHub release (tag_name)**:
  ```
  curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest | jq -r '.tag_name'
  ```
- **GitHub default-branch HEAD commit** (for `fetchFromGitHub`-pinned-to-branch packages
  like yabridge — don't assume the branch is called `main`, check first):
  ```
  curl -s https://api.github.com/repos/<owner>/<repo> | jq -r '.default_branch'
  curl -s https://api.github.com/repos/<owner>/<repo>/commits/<default_branch> | jq -r '.sha'
  ```
- **PyPI**:
  ```
  curl -s https://pypi.org/pypi/<pypi-name>/json | jq -r '.info.version'
  ```
- **npm**:
  ```
  curl -s https://registry.npmjs.org/<package>/latest | jq -r '.version'
  ```
- **VS Code Marketplace**:
  ```
  curl -s -X POST https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery \
    -H "Content-Type: application/json" -H "Accept: application/json;api-version=3.0-preview.1" \
    -d '{"filters":[{"criteria":[{"filterType":7,"value":"<publisher>.<extension>"}]}],"flags":914}' \
    | jq -r '.results[0].extensions[0].versions[0].version'
  ```

## File Paths

- `modules/features/applications/yabridge [n]/yabridge.nix`
  GitHub branch HEAD — `robbert-vdh/yabridge`, default branch is `master` (not `main`,
  despite `version = "main-<rev>"` in the file — that's just a label).
- `modules/features/configs/mcp [n]/_nvim-mcp.nix`
  PyPI — `nvim-mcp` (module/pyproject name is `nvim_mcp`).
- `modules/features/core/development [Nn]/_gh-actions-language-server.nix`
  npm — `gh-actions-language-server`.
- `modules/features/core/development [Nn]/_vscode-bash-debug.nix`
  VS Code Marketplace — `rogalmic.bash-debug`.
- `modules/features/system/fonts [N]/_microsoft-fonts.nix`
  GitHub branch HEAD — `pjobson/Microsoft-365-Fonts`, default branch `main`.
- `modules/features/system/fonts [N]/_neospleen-nerdfont.nix`
  GitHub release — `mbwilding/NeoSpleen`. Same `version` as `_neospleen.nix` below;
  update both together, each has its own regular/medium/bold `fetchurl` hashes
  (plain `sha256`, not SRI — these come from the release's published checksums, not
  `nix store prefetch-file`).
- `modules/features/system/fonts [N]/_neospleen.nix`
  GitHub release — `mbwilding/NeoSpleen`. See above, keep in sync with
  `_neospleen-nerdfont.nix`.
- `modules/features/core/packages [n]/_dtctl.nix`
  GitHub release — `dynatrace-oss/dtctl`. 4 platform sources (linux amd64/arm64,
  darwin amd64/arm64).
- `modules/features/core/packages [n]/_github-copilot.nix`
  GitHub release — `github/app`. 4 platform sources (2 Linux AppImages, 2 darwin
  tarballs).
- `modules/features/core/packages [n]/_open-ecc.nix`
  GitHub release — `mbwilding/open-ecc`. 5 platform sources (linux amd64/arm64,
  freebsd amd64, darwin amd64/arm64).
- `modules/features/core/packages [n]/_power-platform-toolbox.nix`
  GitHub release — `PowerPlatformToolBox/desktop-app`. Linux-only (x86_64-linux).
- `modules/features/core/packages [n]/_steam-achievement-manager.nix`
  GitHub release — `mbwilding/steam-achievement-manager`. 3 platform sources (linux
  x64, darwin amd64/arm64).
