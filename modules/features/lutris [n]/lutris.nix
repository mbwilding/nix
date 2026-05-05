{ inputs, ... }:

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

      home-manager.sharedModules = [
        inputs.self.modules.homeManager.lutris
      ];
    };

  flake.modules.homeManager.lutris =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        lutris
      ];
    };
}
