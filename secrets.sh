#!/usr/bin/env bash

set -euo pipefail

read -s -p "Enter service account token: " OP_SERVICE_ACCOUNT_TOKEN
echo

secrets=(
  "personal|public key|/home/anon/.ssh/authorized_keys"
  "personal|private key|/home/anon/.ssh/personal"
  "personal|public key|/home/anon/.ssh/personal.pub"
  "work|private key|/home/anon/.ssh/work"
  "work|public key|/home/anon/.ssh/work.pub"
  "aur|private key|/home/anon/.ssh/aur"
  "aur|public key|/home/anon/.ssh/aur.pub"
  "GitLab Work|credential|/home/anon/.secrets/gitlab-work"
  "GitHub Work|credential|/home/anon/.secrets/github-work"
  "GitHub Work|username|/home/anon/.secrets/github-work-username"
  "GitHub Personal|credential|/home/anon/.secrets/github-personal"
  "Cargo|credential|/home/anon/.secrets/cargo"
  "ElevenLabs|credential|/home/anon/.secrets/elevenlabs"
  "Pulumi|credential|/home/anon/.secrets/pulumi"
  "Steam|credential|/home/anon/.secrets/steam"
  "Weather|credential|/home/anon/.secrets/weather"
  "Anthropic|credential|/home/anon/.secrets/anthropic"
  "DeepSeek|credential|/home/anon/.secrets/deepseek"
  "OpenAI|credential|/home/anon/.secrets/openai"
  "Home|ip|/home/anon/.secrets/home-ip"
  "Home|wireguardPrivateKey|/home/anon/.secrets/home-wireguard-private-key"
  "Home|wireguardPublicKey|/home/anon/.secrets/home-wireguard-public-key"
  "Home|wireguardEndpoint|/home/anon/.secrets/home-wireguard-endpoint"
  "Work Info|emailId|/home/anon/.secrets/work-email-id"
  "Work Info|emailName|/home/anon/.secrets/work-email-name"
  "Work Info|id|/home/anon/.secrets/work-id"
  "Work Info|name|/home/anon/.secrets/work-name"
  "AWS|json|/home/anon/.secrets/aws.json"
  "Password|credential|/home/anon/.secrets/password"
  "Kubectl|file|/home/anon/.kube/config"
)

for entry in "${secrets[@]}"; do
  IFS='|' read -r item field path <<< "$entry"
  mkdir -p "$(dirname "$path")"
done

op_commands=""
for entry in "${secrets[@]}"; do
  IFS='|' read -r item field path <<< "$entry"
  if [[ "$path" == /home/anon/.ssh/* ]]; then
    op_commands+="op read 'op://Vault/$item/$field' > '$path' && chmod 600 '$path' || exit 1;"
  else
    op_commands+="op read 'op://Vault/$item/$field' > '$path' && sed -zi 's/\n$//' '$path' && chmod 600 '$path' || exit 1;"
  fi
done

NIXPKGS_ALLOW_UNFREE=1 nix-shell -p coreutils _1password-cli --run "
  export OP_SERVICE_ACCOUNT_TOKEN='$OP_SERVICE_ACCOUNT_TOKEN';
  $op_commands
"
