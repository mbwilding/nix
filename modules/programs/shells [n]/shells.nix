{ ... }:

{
  flake.modules.homeManager.shells =
    { secrets, ... }:
    {
      home = {
        sessionPath = [ "$HOME/.cargo/bin" ];

        sessionVariables = {
          ANTHROPIC_API_KEY = secrets.anthropicKey;
          ATLASSIAN_API_TOKEN = secrets.atlassianKey;
          CARGO_REGISTRY_TOKEN = secrets.cargoToken;
          DEEPSEEK_API_KEY = secrets.deepSeekKey;
          ELEVENLABS_API_KEY = secrets.elevenLabsKey;
          # GITHUB_TOKEN = secrets.githubWorkToken;
          GITHUB_TOKEN_PERSONAL = secrets.githubPersonalToken;
          GITHUB_TOKEN_WORK = secrets.githubWorkToken;
          GITLAB_TOKEN = secrets.gitlabWorkToken;
          GITLAB_TOKEN_WORK = secrets.gitlabWorkToken;
          OPENAI_API_KEY = secrets.openAiKey;
          PULUMI_ACCESS_TOKEN = secrets.pulumiToken;
          STEAM_API_KEY = secrets.steamToken;
          WEATHER_API_TOKEN = secrets.weatherKey;
        };

        shellAliases = {
          ${secrets.workName} = "proxychains4 -q -f ~/.config/proxychains/proxychains.conf";
          awsl = "aws sso login --sso-session ${secrets.workName}";
          azl = "az login --scope https://graph.microsoft.com/.default --allow-no-subscriptions";
          battery = "cat /sys/class/power_supply/BAT1/capacity";
          bios = "systemctl reboot --firmware-setup";
          c = "clear";
          g = "git";
          ghp = "set -x GITHUB_TOKEN $GITHUB_TOKEN_PERSONAL";
          ghw = "set -x GITHUB_TOKEN $GITHUB_TOKEN_WORK";
          grep = "grep --color";
          hm-build = "home-manager build -b backup --impure --flake ~/nix#(hostname)";
          hm-expire = "home-manager expire-generations -days";
          hm-switch = "home-manager switch -b backup --impure --flake ~/nix#(hostname)";
          lg = "lazygit";
          ll = "eza -lhg";
          lla = "eza -alhg";
          ls = "eza";
          n = "nvim";
          nix-build = "sudo nixos-rebuild build --impure --flake ~/nix";
          nix-clean = "sudo nix-collect-garbage -d";
          nix-switch = "sudo nixos-rebuild switch --impure --flake ~/nix";
          nix-update = "nix flake update --flake ~/nix";
          nix-upgrade = "sudo nixos-rebuild switch --upgrade --impure --flake ~/nix";
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
      };

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
            set -g __fish_git_prompt_color_upstream yellow

            # Nerd Font git chars
            set -g __fish_git_prompt_char_dirtystate "󰝶 "
            set -g __fish_git_prompt_char_stagedstate "󰸞 "
            set -g __fish_git_prompt_char_untrackedfiles "󰙴 "
            set -g __fish_git_prompt_char_upstream_ahead "󰁝 "
            set -g __fish_git_prompt_char_upstream_behind "󰁅 "
            set -g __fish_git_prompt_char_upstream_equal "󰸞 "
            set -g __fish_git_prompt_char_upstream_diverged "󱐊 "

            # Windows
            set -Ux fish_user_paths \
                /mnt/c/Windows \
                /mnt/c/Windows/System32 \
                /mnt/c/Program Files/PowerShell/7 \
                /mnt/c/Windows/System32/WindowsPowerShell/v1.0 \
                $fish_user_paths
          '';
          functions = {
            fish_prompt = {
              description = "Custom prompt";
              body = ''
                set_color cyan
                echo -n (hostname)' '
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
                  echo -n "$last_status "
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
            ghc = {
              description = "Clone GitHub";
              body = ''
                if test (count $argv) -ge 3
                  set owner $argv[1]
                  set repo $argv[2]
                  set path $argv[3]
                else if test (count $argv) -eq 2
                  set owner $argv[1]
                  set repo $argv[2]
                  set path ~/dev/misc
                else if test (count $argv) -eq 1
                  set owner $argv[1]
                  set path ~/dev/misc
                  read -P "Repo: " repo
                else
                  read -P "Owner: " owner
                  read -P "Repo: " repo
                end
                mkdir -p "$path"
                set dest_dir $path/$repo
                if test -d $dest_dir
                  echo "Already cloned, swapping to directory"
                  cd $dest_dir
                else
                  git clone --recursive "git@github.com:$owner/$repo" $dest_dir
                  cd $dest_dir
                end
              '';
            };
            ghcp = {
              description = "Clone GitHub Personal";
              body = ''
                ghc mbwilding $argv[1] ~/dev/personal
              '';
            };
            ghcw = {
              description = "Clone GitHub Work";
              body = ''
                ghc ${secrets.workName} $argv[1] ~/dev/work
              '';
            };
          };
        };

        zsh = {
          enable = true;
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
