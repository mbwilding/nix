{ secrets, ... }:

{
  home.shellAliases = {
    ${secrets.workName} = "proxychains4 -q -f ~/.config/proxychains/proxychains.conf";
    awsl = "aws sso login --sso-session ${secrets.workName}";
    azl = "az login --scope https://graph.microsoft.com/.default --allow-no-subscriptions";
    battery = "cat /sys/class/power_supply/BAT1/capacity";
    bios = "systemctl reboot --firmware-setup";
    c = "clear";
    g = "git";
    grep = "grep --color";
    hm-expire = "home-manager expire-generations -days";
    lg = "lazygit";
    ll = "eza -lhg";
    lla = "eza -alhg";
    ls = "eza";
    n = "nvim";
    nix-build = "sudo nixos-rebuild build --impure --flake ~/nix";
    nix-clean = "sudo nix-collect-garbage -d";
    nmr = "nmcli radio wifi off && nmcli radio wifi on";
    oc = "opencode";
    power-b = "powerprofilesctl set balanced";
    power-p = "powerprofilesctl set performance";
    power-s = "powerprofilesctl set power-saver";
    q = "exit";
    t = "zellij";
    tree = "eza --tree";
    wgd = "sudo systemctl stop wg-quick-Home";
    wgu = "sudo systemctl start wg-quick-Home";
    wifi-list = "nmcli device wifi list";
  };
}
