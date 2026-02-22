{ ... }:

{
  imports = [
    # ./modules/home/kde.nix
    ./modules/home/hyprland.nix

    ./modules/home/aws.nix
    ./modules/home/btop.nix
    ./modules/home/direnv.nix
    ./modules/home/discord.nix
    ./modules/home/files.nix
    ./modules/home/gh.nix
    ./modules/home/ghostty.nix
    ./modules/home/git.nix
    # ./modules/home/neovim.nix
    ./modules/home/packages.nix
    ./modules/home/ssh.nix
    ./modules/home/starship.nix
    ./modules/home/zsh.nix
  ];

  home = {
    username = "anon";
    homeDirectory = "/home/anon";

    sessionVariables = {
      EDITOR = "nvim";
      XDG_CONFIG_HOME = "$HOME/.config";
      MANPAGER = "nvim +Man!";
      MANWIDTH = "999";
      RUST_LOG = "info";
      AWS_PROFILE = "md";
      AWS_REGION = "ap-southeast-2";
      PULUMI_CONFIG_PASSPHRASE = "";
      DOTNET_ASPIRE_CONTAINER_RUNTIME = "podman";
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      NIXOS_OZONE_WL = "1";
    };

    keyboard = {
      layout = "us";
      variant = "dvorak";
    };

    file.".hushlogin".text = "";

    stateVersion = "25.11";
  };
}
