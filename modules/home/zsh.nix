{ lib, ... }:

let
  work = builtins.readFile /home/anon/.secrets/work-name;

  secretEnvVars = {
    GITLAB_TOKEN = "gitlab-work";
    GITLAB_TOKEN_WORK = "gitlab-work";
    GITHUB_TOKEN = "github-work";
    GITHUB_TOKEN_WORK = "github-work";
    GITHUB_TOKEN_PERSONAL = "github-personal";
    CARGO_REGISTRY_TOKEN = "cargo";
    ELEVENLABS_API_KEY = "elevenlabs";
    PULUMI_ACCESS_TOKEN = "pulumi";
    STEAM_API_KEY = "steam";
    WEATHER_API_TOKEN = "weather";
    ANTHROPIC_API_KEY = "anthropic";
    DEEPSEEK_API_KEY = "deepseek";
    OPENAI_API_KEY = "openai";
  };
in
{
  programs = {
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
        eval "$(atuin init zsh)"
        eval "$(fzf --zsh)"
        eval "$(zoxide init zsh)"
        eval "$(starship init zsh)"
        ## eval "$(jira completion zsh)"
        eval "$(direnv hook zsh)"
        eval "$(gh completion -s zsh)"
        eval "$(op completion zsh)"; compdef _op op
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
        hm-build = "home-manager build -b backup --impure --flake ~/nix#anon";
        hm-rebuild = "home-manager switch -b backup --impure --flake ~/nix#anon";
        nix-build = "sudo nixos-rebuild build --impure --flake ~/nix";
        nix-clean = "sudo nix-collect-garbage -d";
        nix-rebuild = "sudo nixos-rebuild switch --impure --flake ~/nix";
        nix-upgrade = "sudo nixos-rebuild switch --upgrade --impure --flake ~/nix";
        # TODO: Setup proxychains
        ${work} = "proxychains -f ~/.config/proxychains/proxychains.conf";
        t = "zellij";
        tree = "eza --tree";
        wgd = "sudo systemctl stop wg-quick-Home";
        wgu = "sudo systemctl start wg-quick-Home";
      };
      envExtra = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          envVar: secretFile: ''export ${envVar}="$(cat ~/.secrets/${secretFile} 2>/dev/null || true)"''
        ) secretEnvVars
      );
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
