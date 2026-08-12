# Nix Configuration

Make sure this repo exists at /etc/nixos

```bash
./etc/nixos/scripts/secrets.sh
./etc/nixos/scripts/install.sh {SystemHostname}
```

## Temporary Migration

```bash
sudo rm -rf /etc/nixos
sudo mv ~/nix /etc/nixos
sudo chown -R mbwilding:users /etc/nixos
sudo chmod -R o+rX /etc/nixos
sudo nixos-rebuild switch --impure --flake /etc/nixos
```
