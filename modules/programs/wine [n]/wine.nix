{ ... }:

{
  flake.modules.homeManager.wine = { pkgs, ... }: {
    home = {
      packages = with pkgs; [
        wineWow64Packages.staging
        winetricks
      ];

      # TODO: Only do this once
      # activation.winetricksInstalls = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      #   export PATH="${pkgs.wineWow64Packages.staging}/bin:$PATH"
      #   ${pkgs.winetricks}/bin/winetricks --country=AU --optout --unattended ${lib.concatStringsSep " " installs} > /dev/null 2>&1
      # '';
    };
  };
}
