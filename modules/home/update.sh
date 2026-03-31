#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch-github common-updater-scripts

set -euo pipefail

# Get the latest stable vX.Y.Z tag from dotnet/roslyn
# Excludes VSCode-CSharp-* and Visual-Studio-* tags
latest_tag=$(
  curl -s "https://api.github.com/repos/dotnet/roslyn/tags?per_page=100" \
    | jq -r '.[].name' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -1
)

version="${latest_tag#v}"
echo "Latest roslyn tag: $latest_tag (version: $version)"

hash=$(nix-prefetch-github dotnet roslyn --rev "$latest_tag" | jq -r '.hash')
echo "Hash: $hash"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_file="$script_dir/roslyn-ls.nix"

update-source-version roslyn-ls "$version" "$hash" \
  --file="$nix_file" \
  --source-key=src
