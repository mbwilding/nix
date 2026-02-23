{ secrets, ... }:

let
  work = secrets.workName;
in
{
  home.sessionVariables = {
    GITLAB_TOKEN = secrets.gitlabWorkToken;
    GITLAB_TOKEN_WORK = secrets.gitlabWorkToken;
    GITHUB_TOKEN = secrets.githubWorkToken;
    GITHUB_TOKEN_WORK = secrets.githubWorkToken;
    GITHUB_TOKEN_PERSONAL = secrets.githubPersonalToken;
    CARGO_REGISTRY_TOKEN = secrets.cargoToken;
    ELEVENLABS_API_KEY = secrets.elevenLabsKey;
    PULUMI_ACCESS_TOKEN = secrets.pulumiToken;
    STEAM_API_KEY = secrets.steamToken;
    WEATHER_API_TOKEN = secrets.weatherKey;
    ANTHROPIC_API_KEY = secrets.anthropicKey;
    DEEPSEEK_API_KEY = secrets.deepSeekKey;
    OPENAI_API_KEY = secrets.openAiKey;
  };

  programs = {
    atuin = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    starship = {
      enable = true;
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

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      silent = false;
      config = {
        global = {
          warn_timeout = "2m";
          hide_env_diff = true;
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
      shellAliases = {
        awsl = "aws sso login --sso-session ${work}";
        azl = "az login --scope https://graph.microsoft.com/.default --allow-no-subscriptions";
        bios = "systemctl reboot --firmware-setup";
        c = "clear";
        ghp = "export GITHUB_TOKEN=$GITHUB_TOKEN_PERSONAL";
        ghw = "export GITHUB_TOKEN=$GITHUB_TOKEN_WORK";
        grep = "grep --color";
        # keys = "sudo -e /etc/keyd/default.conf && sudo systemctl restart keyd";
        lg = "lazygit";
        ll = "eza -lhg";
        lla = "eza -alhg";
        ls = "eza";
        n = "nvim";
        nmr = "nmcli radio wifi off && nmcli radio wifi on";
        oc = "opencode";
        q = "exit";
        hm-build = "home-manager build -b backup --impure --flake ~/nix#$(hostname)";
        hm-switch = "home-manager switch -b backup --impure --flake ~/nix#$(hostname) && exec zsh";
        hm-expire = "home-manager expire-generations -days";
        nix-build = "sudo nixos-rebuild build --impure --flake ~/nix";
        nix-clean = "sudo nix-collect-garbage -d";
        nix-switch = "sudo nixos-rebuild switch --impure --flake ~/nix && exec zsh";
        nix-upgrade = "sudo nixos-rebuild switch --upgrade --impure --flake ~/nix && exec zsh";
        power-p = "powerprofilesctl set performance";
        power-b = "powerprofilesctl set balanced";
        power-s = "powerprofilesctl set power-saver";
        battery = "cat /sys/class/power_supply/BAT1/capacity";
        wifi-list = "nmcli device wifi list";
        # TODO: Setup proxychains
        ${work} = "proxychains -f ~/.config/proxychains/proxychains.conf";
        t = "zellij";
        tree = "eza --tree";
        wgd = "sudo systemctl stop wg-quick-Home";
        wgu = "sudo systemctl start wg-quick-Home";
      };
      zplug = {
        enable = true;
        plugins = [
          { name = "zsh-users/zsh-syntax-highlighting"; }
          { name = "zsh-users/zsh-autosuggestions"; }
          { name = "zsh-users/zsh-completions"; }
          { name = "Aloxaf/fzf-tab"; }
        ];
      };
    };
  };
}
