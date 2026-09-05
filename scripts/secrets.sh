#!/usr/bin/env bash

set -euo pipefail

refresh=false
if [[ "${1:-}" == "--refresh" ]]; then
  refresh=true
fi

token_file="$HOME/.secrets/1password"
mkdir -p "$(dirname "$token_file")"

if [[ -s "$token_file" ]]; then
  OP_SERVICE_ACCOUNT_TOKEN=$(<"$token_file")
else
  read -s -p "Enter service account token: " OP_SERVICE_ACCOUNT_TOKEN
  echo
  printf '%s' "$OP_SERVICE_ACCOUNT_TOKEN" > "$token_file"
  chmod 600 "$token_file"
fi

secrets=(
  "AWS|json|$HOME/.secrets/aws.json"
  "Anthropic|credential|$HOME/.secrets/anthropic"
  "Artifactory|credential|$HOME/.secrets/artifactory"
  "Atlassian|credential|$HOME/.secrets/atlassian"
  "Atlassian|rovo|$HOME/.secrets/atlassian-rovo"
  "Cargo|credential|$HOME/.secrets/cargo"
  "Crates Work|password|$HOME/.secrets/crates-work"
  "Databases|json|$HOME/.secrets/databases.json"
  "DeepSeek|credential|$HOME/.secrets/deepseek"
  "Dynamics|credentials|$HOME/.secrets/dynamics.json"
  "ElevenLabs|credential|$HOME/.secrets/elevenlabs"
  "Figma|credential|$HOME/.secrets/figma"
  "GitHub Personal|credential|$HOME/.secrets/github-personal"
  "GitHub Work|credential|$HOME/.secrets/github-work"
  "GitHub Work|username|$HOME/.secrets/github-work-username"
  "GitLab Personal|credential|$HOME/.secrets/gitlab-personal"
  "GitLab Work|credential|$HOME/.secrets/gitlab-work"
  "Home|ip|$HOME/.secrets/home-ip"
  "Home|wireguardEndpoint|$HOME/.secrets/home-wireguard-endpoint"
  "Home|wireguardPrivateKey|$HOME/.secrets/home-wireguard-private-key"
  "Home|wireguardPublicKey|$HOME/.secrets/home-wireguard-public-key"
  "Kubectl|file|$HOME/.kube/config"
  "Lucid|credential|$HOME/.secrets/lucid"
  "OpenAI|credential|$HOME/.secrets/openai"
  "Packages|json|$HOME/.secrets/packages.json"
  "Password|credential|$HOME/.secrets/password"
  "Pulumi|credential|$HOME/.secrets/pulumi"
  "Reaper|reaper-license.rk|$HOME/.config/REAPER/reaper-license.rk"
  "Reaper|reaper-reginfo2.ini|$HOME/.config/REAPER/reaper-reginfo2.ini"
  "Steam|credential|$HOME/.secrets/steam"
  "Voip|password|$HOME/.secrets/voip-password"
  "Voip|username|$HOME/.secrets/voip-username"
  "Weather|credential|$HOME/.secrets/weather"
  "Wifi Home|network name|$HOME/.secrets/wifi-home-ssid"
  "Wifi Home|wireless network password|$HOME/.secrets/wifi-home-password"
  "Wifi Parents|network name|$HOME/.secrets/wifi-parents-ssid"
  "Wifi Parents|wireless network password|$HOME/.secrets/wifi-parents-password"
  "Work Info|emailId|$HOME/.secrets/work-email-id"
  "Work Info|emailName|$HOME/.secrets/work-email-name"
  "Work Info|id|$HOME/.secrets/work-id"
  "Work Info|name|$HOME/.secrets/work-name"
  "aur|private key|$HOME/.ssh/aur"
  "aur|public key|$HOME/.ssh/aur.pub"
  "personal|private key|$HOME/.ssh/personal"
  "personal|public key|$HOME/.ssh/authorized_keys"
  "personal|public key|$HOME/.ssh/personal.pub"
  "work|private key|$HOME/.ssh/work"
  "work|public key|$HOME/.ssh/work.pub"
)

for entry in "${secrets[@]}"; do
  IFS='|' read -r item field path <<< "$entry"
  mkdir -p "$(dirname "$path")"
done

op_commands=""
for entry in "${secrets[@]}"; do
  IFS='|' read -r item field path <<< "$entry"
  if [[ "$refresh" == false && -e "$path" ]]; then
    op_commands+="echo 'SKIP: $item ($field) (already exists)';"
    continue
  fi
  if [[ "$path" == $HOME/.ssh/* ]]; then
    cmd="op read 'op://Vault/$item/$field' > '$path' && chmod 600 '$path'"
  else
    cmd="op read 'op://Vault/$item/$field' > '$path' && sed -zi 's/\n$//' '$path' && chmod 600 '$path'"
  fi
  op_commands+="if $cmd; then echo 'OK: $item ($field)'; else echo 'FAIL: $item ($field)' >&2; failures+=(\"$item ($field)\"); fi;"
done

summary=$(cat <<'EOF'
if [ ${#failures[@]} -gt 0 ]; then
  echo
  echo "Failed (${#failures[@]}):" >&2
  printf '  - %s\n' "${failures[@]}" >&2
  exit 1
else
  echo
  echo "All secrets synced successfully."
fi
EOF
)

NIXPKGS_ALLOW_UNFREE=1 nix-shell --extra-experimental-features flakes -p coreutils _1password-cli --run "
  export OP_SERVICE_ACCOUNT_TOKEN='$OP_SERVICE_ACCOUNT_TOKEN';
  failures=();
  $op_commands
  $summary
"
