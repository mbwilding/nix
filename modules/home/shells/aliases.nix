{ secrets, ... }:

{
  home.shellAliases = {
    awsl = "aws sso login --sso-session ${secrets.workName}";
    azl = "az login --scope https://graph.microsoft.com/.default --allow-no-subscriptions";
    bios = "systemctl reboot --firmware-setup";
    c = "clear";
    grep = "grep --color";
    lg = "lazygit";
    ll = "eza -lhg";
    lla = "eza -alhg";
    ls = "eza";
    n = "nvim";
    nmr = "nmcli radio wifi off && nmcli radio wifi on";
    oc = "opencode";
    q = "exit";
    hm-expire = "home-manager expire-generations -days";
    nix-build = "sudo nixos-rebuild build --impure --flake ~/nix";
    nix-clean = "sudo nix-collect-garbage -d";
    power-p = "powerprofilesctl set performance";
    power-b = "powerprofilesctl set balanced";
    power-s = "powerprofilesctl set power-saver";
    battery = "cat /sys/class/power_supply/BAT1/capacity";
    wifi-list = "nmcli device wifi list";
    ${secrets.workName} = "proxychains4 -f ~/.config/proxychains/proxychains.conf";
    t = "zellij";
    tree = "eza --tree";
    wgd = "sudo systemctl stop wg-quick-Home";
    wgu = "sudo systemctl start wg-quick-Home";
  };
}
