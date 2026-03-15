{
  pkgsPhone,
  pkgsStablePhone,
  secrets,
  font,
  inputs,
  hostname,
  homeDirectory,
  username,
  ...
}:

{
  nix = {
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
  };

  # environment.packages = with pkgsPhone; [
  #   git
  #   neovim
  #   vim
  # ];

  home-manager = {
    config = ../../home.nix;

    extraSpecialArgs = {
      inherit
        secrets
        font
        inputs
        hostname
        homeDirectory
        username
        ;

      isDesktop = false;
      pkgs = pkgsPhone;
      pkgsStable = pkgsStablePhone;
    };
  };

  system.stateVersion = "24.05";
}
