#!/usr/bin/env bash

set -euo pipefail

if [ -n "${1:-}" ]; then
  HOST="$1"
else
  read -rp "Hostname: " HOST
fi

HOST="${HOST// /}"

ARGS=()


# NOTE: LXC
if [ "$HOST" = "vm" ]; then
  ARGS=(--option sandbox false)
fi

sudo nixos-rebuild boot --impure --flake "$HOME/nix#$HOST" "${ARGS[@]}"
echo "Reboot"
