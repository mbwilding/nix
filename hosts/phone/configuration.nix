{
  pkgs,
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
