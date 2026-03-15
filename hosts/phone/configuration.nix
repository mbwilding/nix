{
  pkgsPhone,
  pkgsStablePhone,
  secrets,
  font,
  inputs,
  hostname,
  homeDirectory,
  ...
}:

{
  nix = {
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
  };

  # environment.packages = with pkgs; [
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
        ;

      isDesktop = false;
      pkgs = pkgsPhone;
      pkgsStable = pkgsStablePhone;
    };
  };

  system.stateVersion = "24.05";
}
