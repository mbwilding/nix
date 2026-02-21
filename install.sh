#!/usr/bin/env bash

set -euo pipefail

flake_path=~/nix
if [ -n "$1" ]; then
  flake_path="$flake_path#$1"
fi

sudo nixos-rebuild switch --impure --flake "$flake_path"
