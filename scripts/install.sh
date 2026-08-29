#!/usr/bin/env bash

set -euo pipefail

if [ -n "${1:-}" ]; then
  HOST="$1"
else
  read -rp "Hostname: " HOST
fi

HOST="${HOST// /}"

EXTRA_ARGS=()
if [ "$HOST" = "container" ]; then
  EXTRA_ARGS+=(--option sandbox false)
fi

sudo nixos-rebuild boot --impure --flake "/etc/nixos#$HOST" "${EXTRA_ARGS[@]}"
echo "Reboot"
