{
  pkgsStable,
  secrets,
  font,
  ...
}:

{
  imports = [
    ../../modules/home/atuin.nix
    ../../modules/home/btop.nix
    ../../modules/home/direnv.nix
    ../../modules/home/fzf.nix
    ../../modules/home/git.nix
    ../../modules/home/lazygit.nix
    ../../modules/home/shells
    ../../modules/home/ssh.nix
    ../../modules/home/yazi.nix
    ../../modules/home/zoxide.nix

    ../../modules/home/packages.nix
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
    };

    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit
        pkgsStable
        secrets
        font
        ;
    };

    file.".hushlogin".text = "";

    stateVersion = "25.11";
  };
}
