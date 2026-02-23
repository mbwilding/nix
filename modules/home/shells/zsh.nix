{ secrets, ... }:

let
  work = secrets.workName;
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
        ghp = "export GITHUB_TOKEN=$GITHUB_TOKEN_PERSONAL";
        ghw = "export GITHUB_TOKEN=$GITHUB_TOKEN_WORK";
        hm-build = "home-manager build -b backup --impure --flake ~/nix#$(hostname)";
        hm-switch = "home-manager switch -b backup --impure --flake ~/nix#$(hostname) && exec zsh";
        nix-switch = "sudo nixos-rebuild switch --impure --flake ~/nix && exec zsh";
        nix-upgrade = "sudo nixos-rebuild switch --upgrade --impure --flake ~/nix && exec zsh";
      };
    };
  };
}
