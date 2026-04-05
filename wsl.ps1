# https://nixos.wiki/wiki/WSL

wsl --update

$url = (Invoke-RestMethod https://api.github.com/repos/nix-community/NixOS-WSL/releases/latest).assets |
       Where-Object { $_.name -eq "nixos.wsl" } |
       Select-Object -ExpandProperty browser_download_url

Invoke-WebRequest $url -OutFile nixos.wsl

wsl --install --from-file nixos.wsl
wsl -d NixOS

## Comment out home manager in the mkHost section
# nix shell --extra-experimental-features "nix-command flakes"  nixpkgs#git
# git clone https://github.com/mbwilding/nix
# cd nix
# sudo nixos-rebuild boot --impure --flake .#wsl
# wsl -t NixOS
# wsl -d NixOS --user root exit
# wsl -t NixOS
## Open NixOS
## Un-comment initial thing
# sudo nixos-rebuild switch --impure --flake .#wsl
