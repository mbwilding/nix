{ lib, isDesktop, ... }:
{
  imports =
    lib.optionals isDesktop [
      # ./modules/home/kde.nix
      ./modules/home/hyprland.nix

      # ./modules/home/neovim.nix

      ./modules/home/discord.nix
      ./modules/home/ghostty.nix
      ./modules/home/jetbrains.nix
      ./modules/home/mpv.nix
      ./modules/home/wine.nix
    ]
    ++ [
      ./modules/home/atuin.nix
      ./modules/home/aws.nix
      ./modules/home/btop.nix
      ./modules/home/dapr.nix
      ./modules/home/direnv.nix
      ./modules/home/dotnet.nix
      ./modules/home/files.nix
      ./modules/home/fzf.nix
      ./modules/home/gh.nix
      ./modules/home/git.nix
      ./modules/home/lazygit.nix
      ./modules/home/lazysql.nix
      ./modules/home/packages.nix
      ./modules/home/proxychains.nix
      ./modules/home/shells
      ./modules/home/ssh.nix
      ./modules/home/yazi.nix
      ./modules/home/zoxide.nix
    ];

  news.display = "silent";

  home = {
    sessionVariables = {
      EDITOR = "nvim";
      XDG_CONFIG_HOME = "$HOME/.config";
      MANPAGER = "nvim +Man!";
      MANWIDTH = "999";
      RUST_LOG = "info";
      PULUMI_CONFIG_PASSPHRASE = "";
    }
    // lib.optionalAttrs isDesktop {
      NIXOS_OZONE_WL = "1";
    };

    keyboard = lib.mkIf isDesktop {
      layout = "us";
      variant = "dvorak";
    };

    file.".hushlogin".text = "";

    stateVersion = "25.11";
  }
  // lib.optionalAttrs isDesktop {
    username = "anon";
    homeDirectory = "/home/anon";
  };
}
