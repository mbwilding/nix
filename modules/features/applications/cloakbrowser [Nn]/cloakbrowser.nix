{ inputs, ... }:

{
  flake.lib.overlays.cloakbrowser = final: prev: {
    cloakbrowser = inputs.cloakbrowser.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  flake.modules.nixos.cloakbrowser = {
    nixpkgs.overlays = [
      inputs.self.lib.overlays.cloakbrowser
    ];
  };

  flake.modules.homeManager.cloakbrowser =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.cloakbrowser ];
    };
}
