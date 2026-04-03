# Nix Configuration

- Make sure this repo exists at ~/nix
- Run ~/nix/secrets.sh
  - Paste in the service account token (Vault/1Password/credential)
- Run ~/nix/install.sh {hostname}

## Dev Shell Templates

Project-specific dev shells live in `templates/`. To bootstrap a new project:

```bash
# Rust project with openssl (e.g. microkit)
cd ~/personal/myproject
nix flake init -t ~/nix#microkit
direnv allow # if using direnv - activates automatically on cd
```

The `microkit` template provides: `cargo`, `rustc`, `rustfmt`, `clippy`,
`rust-analyzer`, `pkg-config`, and `openssl`.

To enter the shell manually without direnv:

```bash
nix develop
```
