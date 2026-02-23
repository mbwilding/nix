{ secrets, ... }:

{
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting

        # Git prompt settings
        set -g __fish_git_prompt_showdirtystate 1
        set -g __fish_git_prompt_showuntrackedfiles 1
        set -g __fish_git_prompt_showupstream auto
        set -g __fish_git_prompt_showcolorhints 1
        set -g __fish_git_prompt_color_branch yellow
        set -g __fish_git_prompt_color_dirtystate red
        set -g __fish_git_prompt_color_stagedstate green
      '';
      shellAliases = {
        awsl = "aws sso login --sso-session ${secrets.workName}";
        azl = "az login --scope https://graph.microsoft.com/.default --allow-no-subscriptions";
        bios = "systemctl reboot --firmware-setup";
        c = "clear";
        ghp = "set -x GITHUB_TOKEN $GITHUB_TOKEN_PERSONAL";
        ghw = "set -x GITHUB_TOKEN $GITHUB_TOKEN_WORK";
        grep = "grep --color";
        lg = "lazygit";
        ll = "eza -lhg";
        lla = "eza -alhg";
        ls = "eza";
        n = "nvim";
        nmr = "nmcli radio wifi off && nmcli radio wifi on";
        oc = "opencode";
        q = "exit";
        hm-build = "home-manager build -b backup --impure --flake ~/nix#(hostname)";
        hm-switch = "home-manager switch -b backup --impure --flake ~/nix#(hostname) && exec fish";
        hm-expire = "home-manager expire-generations -days";
        nix-build = "sudo nixos-rebuild build --impure --flake ~/nix";
        nix-clean = "sudo nix-collect-garbage -d";
        nix-switch = "sudo nixos-rebuild switch --impure --flake ~/nix && exec fish";
        nix-upgrade = "sudo nixos-rebuild switch --upgrade --impure --flake ~/nix && exec fish";
        power-p = "powerprofilesctl set performance";
        power-b = "powerprofilesctl set balanced";
        power-s = "powerprofilesctl set power-saver";
        battery = "cat /sys/class/power_supply/BAT1/capacity";
        wifi-list = "nmcli device wifi list";
        # TODO: Configure proxychains
        ${secrets.workName} = "proxychains -f ~/.config/proxychains/proxychains.conf";
        t = "zellij";
        tree = "eza --tree";
        wgd = "sudo systemctl stop wg-quick-Home";
        wgu = "sudo systemctl start wg-quick-Home";
      };
      functions = {
        fish_prompt = {
          description = "Custom prompt";
          body = ''
            set -l last_status $status
            set_color blue
            echo -n (prompt_pwd)
            set_color yellow
            echo -n (fish_git_prompt)
            set_color normal
            echo
            if test $last_status -eq 0
              set_color --bold green
            else
              set_color --bold red
            end
            echo -n '❯ '
            set_color normal
          '';
        };
        fish_right_prompt = {
          description = "Right prompt with battery";
          body = ''
            set -l bat /sys/class/power_supply/BAT1
            if not test -d $bat
              return
            end
            set -l cap (cat $bat/capacity)
            set -l stat (cat $bat/status)
            if test "$stat" = Charging
              set_color --bold yellow
              echo -n "󰂄 $cap%"
            else if test $cap -le 20
              set_color --bold red
              echo -n "󰂎 $cap%"
            else if test $cap -le 40
              set_color --bold yellow
              echo -n "󰂃 $cap%"
            else if test $cap -le 60
              set_color --bold green
              echo -n "󰁹 $cap%"
            end
            set_color normal
          '';
        };
        wifi-connect = {
          description = "Connect to a WiFi network via nmcli";
          body = ''
            read -P "Enter SSID: " ssid
            read -sP "Enter Password: " password
            echo
            nmcli device wifi connect $ssid password $password
          '';
        };
      };
    };
  };
}
