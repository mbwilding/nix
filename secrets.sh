#!/usr/bin/env bash

set -euo pipefail

read -s -p "Enter service account token: " OP_SERVICE_ACCOUNT_TOKEN
echo

secrets=(
  "personal|public key|$HOME/.ssh/authorized_keys"
  "personal|private key|$HOME/.ssh/personal"
  "personal|public key|$HOME/.ssh/personal.pub"
  "work|private key|$HOME/.ssh/work"
  "work|public key|$HOME/.ssh/work.pub"
  "aur|private key|$HOME/.ssh/aur"
  "aur|public key|$HOME/.ssh/aur.pub"
  "GitLab Work|credential|$HOME/.secrets/gitlab-work"
  "GitHub Work|credential|$HOME/.secrets/github-work"
  "GitHub Work|username|$HOME/.secrets/github-work-username"
  "GitHub Personal|credential|$HOME/.secrets/github-personal"
  "Cargo|credential|$HOME/.secrets/cargo"
  "ElevenLabs|credential|$HOME/.secrets/elevenlabs"
  "Pulumi|credential|$HOME/.secrets/pulumi"
  "Steam|credential|$HOME/.secrets/steam"
  "Weather|credential|$HOME/.secrets/weather"
  "Anthropic|credential|$HOME/.secrets/anthropic"
  "DeepSeek|credential|$HOME/.secrets/deepseek"
  "OpenAI|credential|$HOME/.secrets/openai"
  "Home|ip|$HOME/.secrets/home-ip"
  "Home|wireguardPrivateKey|$HOME/.secrets/home-wireguard-private-key"
  "Home|wireguardPublicKey|$HOME/.secrets/home-wireguard-public-key"
  "Home|wireguardEndpoint|$HOME/.secrets/home-wireguard-endpoint"
  "Work Info|emailId|$HOME/.secrets/work-email-id"
  "Work Info|emailName|$HOME/.secrets/work-email-name"
  "Work Info|id|$HOME/.secrets/work-id"
  "Work Info|name|$HOME/.secrets/work-name"
  "AWS|json|$HOME/.secrets/aws.json"
  "Password|credential|$HOME/.secrets/password"
  "Kubectl|file|$HOME/.kube/config"
  "Wifi Home|network name|$HOME/.secrets/wifi-home-ssid"
  "Wifi Home|wireless network password|$HOME/.secrets/wifi-home-password"
  "Wifi Parents|network name|$HOME/.secrets/wifi-parents-ssid"
  "Wifi Parents|wireless network password|$HOME/.secrets/wifi-parents-password"
)

for entry in "${secrets[@]}"; do
  IFS='|' read -r item field path <<< "$entry"
  mkdir -p "$(dirname "$path")"
done

op_commands=""
for entry in "${secrets[@]}"; do
  IFS='|' read -r item field path <<< "$entry"
  if [[ "$path" == $HOME/.ssh/* ]]; then
    op_commands+="op read 'op://Vault/$item/$field' > '$path' && chmod 600 '$path' || exit 1;"
  else
    op_commands+="op read 'op://Vault/$item/$field' > '$path' && sed -zi 's/\n$//' '$path' && chmod 600 '$path' || exit 1;"
  fi
done

NIXPKGS_ALLOW_UNFREE=1 nix-shell -p coreutils _1password-cli --run "
  export OP_SERVICE_ACCOUNT_TOKEN='$OP_SERVICE_ACCOUNT_TOKEN';
  $op_commands
"
