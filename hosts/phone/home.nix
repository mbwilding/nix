{ ... }:

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
  ];

  news.display = "silent";

  home = {
    sessionVariables = {
      EDITOR = "nvim";
      XDG_CONFIG_HOME = "$HOME/.config";
      MANPAGER = "nvim +Man!";
      MANWIDTH = "999";
      RUST_LOG = "info";
      NIX_PATH = "nixpkgs=flake:nixpkgs";
    };

    file.".hushlogin".text = "";

    stateVersion = "25.11";
  };
}
