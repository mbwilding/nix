{
  flake.modules.nixos.lutris =
    { ... }:
    {
      nixpkgs.overlays = [
        (_: prev: {
          openldap = prev.openldap.overrideAttrs {
            doCheck = false; # False is a bit more honest on x86_64 systems
          };
        })
      ];
    };

  flake.modules.homeManager.lutris =
    {
      pkgs,
      lib,
      work,
      ...
    }:
    {
      programs = lib.mkIf (!work) {
        lutris = {
          enable = true;
          protonPackages = [
            pkgs.proton-ge-bin
          ];
        };
      };
    };
}
