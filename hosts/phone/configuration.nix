{
  pkgs,
  pkgsStable,
  secrets,
  font,
  inputs,
  hostname,
  ...
}:

{
  nix = {
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
  };

  environment.packages = with pkgs; [
    git
    neovim
    vim
  ];

  home-manager = {
    config = ../../home.nix;
    extraSpecialArgs = {
      inherit
        pkgsStable
        secrets
        font
        inputs
        hostname
        ;

      isDesktop = false;
    };
  };

  system.stateVersion = "24.05";
}
