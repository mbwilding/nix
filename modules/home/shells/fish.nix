{ ... }:

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
        set -g __fish_git_prompt_color_prefix yellow
        set -g __fish_git_prompt_color_suffix yellow

        # Nerd Font git chars
        set -g __fish_git_prompt_char_dirtystate "✎"
        set -g __fish_git_prompt_char_stagedstate "●"
        set -g __fish_git_prompt_char_untrackedfiles "…"
        set -g __fish_git_prompt_char_upstream_ahead "↑"
        set -g __fish_git_prompt_char_upstream_behind "↓"
      '';
      shellAliases = {
        ghp = "set -x GITHUB_TOKEN $GITHUB_TOKEN_PERSONAL";
        ghw = "set -x GITHUB_TOKEN $GITHUB_TOKEN_WORK";
        hm-build = "home-manager build -b backup --impure --flake ~/nix#(hostname)";
        hm-switch = "home-manager switch -b backup --impure --flake ~/nix#(hostname) && exec fish";
        nix-switch = "sudo nixos-rebuild switch --impure --flake ~/nix && exec fish";
        nix-upgrade = "sudo nixos-rebuild switch --upgrade --impure --flake ~/nix && exec fish";
      };
      functions = {
        fish_prompt = {
          description = "Custom prompt";
          body = ''
            set -l last_status $status
            set_color normal
            set_color blue
            echo -n (prompt_pwd)
            set -l git_info (fish_git_prompt)
            if test -n "$git_info"
              set_color yellow
              echo -n "  "
              echo -n (string trim --left $git_info)
            end
            set_color normal
            echo
            if test $last_status -eq 0
              set_color --bold green
            else
              set_color --bold red
              echo -n "$last_status "
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
