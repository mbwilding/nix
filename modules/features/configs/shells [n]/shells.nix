{ ... }:

{
  flake.modules.homeManager.shells =
    {
      lib,
      config,
      pkgs,
      work ? false,
      ...
    }:
    let
      hostnameExpr = if work then "'RWMP4914'" else "(hostname)";
    in
    {
      home = {
        sessionPath = [ "$HOME/.cargo/bin" ];

        file = {
          ".hushlogin".text = "";
        };

        sessionVariables = {
          XDG_CONFIG_HOME = lib.mkForce "$HOME/.config";
          MANPAGER = "nvim +Man!";
          MANWIDTH = "999";
          RUST_LOG = "info";
        };

        shellAliases = {
          battery = "cat /sys/class/power_supply/BAT1/capacity";
          bios = "systemctl reboot --firmware-setup";
          c = "clear";
          dn = "nvim /mnt/mbwilding/Documents/DailyNotes.md";
          g = "git";
          grep = "grep --color";
          hm-build = "home-manager build --no-out-link -b backup --impure --flake ~/nix#(hostname)";
          hm-build-link = "home-manager build -b backup --impure --flake ~/nix#(hostname)";
          hm-clean = "home-manager expire-generations -days";
          hm-switch = "home-manager switch -b backup --impure --flake ~/nix#(hostname)";
          lg = "lazygit";
          ll = "eza -lhg";
          lla = "eza -alhg";
          ls = "eza";
          n = "nvim";
          nix-boot = "sudo nixos-rebuild boot --impure --flake ~/nix";
          nix-build = "nixos-rebuild build --no-link --impure --flake ~/nix";
          nix-build-link = "sudo nixos-rebuild build --impure --flake ~/nix";
          nix-clean = "sudo nix-collect-garbage -d";
          nix-switch = "sudo nixos-rebuild switch --impure --flake ~/nix";
          nix-update = "nix flake update --flake ~/nix";
          nmr = "nmcli radio wifi off && nmcli radio wifi on";
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
      };

      programs = {
        fish = {
          enable = true;
          plugins = [
            {
              name = "fzf-fish";
              src = pkgs.fishPlugins.fzf-fish.src;
            }
            {
              name = "fifc";
              src = pkgs.fishPlugins.fifc.src;
            }
            {
              name = "puffer";
              src = pkgs.fishPlugins.puffer.src;
            }
            {
              name = "bass";
              src = pkgs.fishPlugins.bass.src;
            }
            {
              name = "forgit";
              src = pkgs.fishPlugins.forgit.src;
            }
          ];
          interactiveShellInit = ''
            # Suppress greeting
            set -g fish_greeting

            # Vi
            fish_vi_key_bindings

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
            set -g __fish_git_prompt_color_upstream yellow

            # Nerd Font git chars
            set -g __fish_git_prompt_char_dirtystate "󰝶 "
            set -g __fish_git_prompt_char_stagedstate "󰸞 "
            set -g __fish_git_prompt_char_untrackedfiles "󰙴 "
            set -g __fish_git_prompt_char_upstream_ahead "󰁝 "
            set -g __fish_git_prompt_char_upstream_behind "󰁅 "
            set -g __fish_git_prompt_char_upstream_equal "󰸞 "
            set -g __fish_git_prompt_char_upstream_diverged "󱐊 "
          '';
          functions = {
            fish_prompt = {
              description = "Custom prompt";
              body = ''
                set_color cyan
                echo -n (whoami)'@'${hostnameExpr}' '
                set -l last_status $status
                set_color normal
                set_color blue
                echo -n (prompt_pwd)
                set -l njobs (jobs -p | count)
                if test $njobs -gt 0
                  set_color --bold magenta
                  echo -n " [$njobs]"
                end
                set -l git_info (fish_git_prompt)
                if test -n "$git_info"
                  set_color yellow
                  echo -n ""
                  echo -n (string trim --left $git_info)
                end
                set_color normal
                echo
                if test $last_status -eq 0
                  set_color --bold green
                else
                  set_color --bold red
                  echo -n (fish_status_to_signal $last_status)" "
                end
                echo -n '❯ '
                set_color normal
              '';
            };
            fish_right_prompt = {
              description = "Right prompt with time and battery";
              body = ''
                set_color --bold white
                echo -n (date '+%H:%M:%S')" "

                set -l bat /sys/class/power_supply/BAT1
                if test -d $bat
                  set -l cap (cat $bat/capacity)
                  set -l stat (cat $bat/status)

                  if test "$stat" = Charging
                    set_color --bold yellow
                    echo -n "$cap% 󰂄 "
                  else if test $cap -lt 20
                    set_color --bold red
                    echo -n "$cap% 󰁺 "
                  else if test $cap -lt 40
                    set_color --bold yellow
                    echo -n "$cap% 󰁻 "
                  else if test $cap -lt 60
                    set_color --bold yellow
                    echo -n "$cap% 󰁼 "
                  else if test $cap -lt 80
                    set_color --bold white
                    echo -n "$cap% 󰁽 "
                  else
                    set_color --bold green
                    echo -n "$cap% 󰁹 "
                  end
                end
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
            nix-run = {
              description = "Run a Nix package without installing";
              body = "nix run nixpkgs#$argv[1]";
            };
          };
        };

        zsh = {
          enable = true;
          dotDir = "${config.xdg.configHome}/zsh";
          autocd = true;
          autosuggestion.enable = true;
          enableCompletion = true;
          syntaxHighlighting.enable = true;
          history.size = 10000;
          oh-my-zsh = {
            enable = true;
            plugins = [
              "aws"
              "command-not-found"
              "git"
              "kubectl"
              "kubectx"
              "sudo"
            ];
          };
          initContent = ''
            wifi-connect() {
              echo -n "Enter SSID: "
              read ssid
              echo -n "Enter Password: "
              read -s password
              echo
              nmcli device wifi connect "$ssid" password "$password"
            }
          '';
        };

        starship = {
          enable = true;
          enableFishIntegration = false;
          enableZshIntegration = true;
          settings = {
            add_newline = true;
            character.success_symbol = "[❯](bold green)";
            battery = {
              full_symbol = "󰁹 ";
              charging_symbol = "󰂄 ";
              discharging_symbol = "󰂃 ";
              unknown_symbol = "󰁽 ";
              empty_symbol = "󰂎 ";
              display = [
                {
                  threshold = 20;
                  style = "bold red";
                }
                {
                  threshold = 40;
                  style = "bold yellow";
                }
                {
                  threshold = 60;
                  style = "bold green";
                }
              ];
            };
          };
        };
      };
    };
}
