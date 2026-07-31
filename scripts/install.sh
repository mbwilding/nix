#!/usr/bin/env bash

set -euo pipefail

if [ -n "${1:-}" ]; then
  HOST="$1"
else
  read -rp "Hostname: " HOST
fi

HOST="${HOST// /}"

sudo nixos-rebuild boot --impure --flake "$HOME/nix#$HOST"
echo "Reboot"
