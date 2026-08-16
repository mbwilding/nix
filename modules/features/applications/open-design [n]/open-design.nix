{ inputs, ... }:

{
  flake.modules.homeManager.open-design =
    { pkgs, ... }:

    let
      velaCli = pkgs.callPackage ./_vela-cli.nix { };
    in
    {
      imports = [ inputs.open-design.homeManagerModules.default ];

      services.open-design = {
        enable = true;
        autoStart = true;
        webFrontend.enable = true;

        extraEnv = {
          VELA_BIN = "${velaCli}/bin/vela";
        };
      };
    };
}
