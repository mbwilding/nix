{ inputs, ... }:

{
  flake.modules.homeManager.lazydotnet =
    { pkgs, ... }:
    {
      home = {
        packages = [
          inputs.lazydotnet.packages.${pkgs.stdenv.hostPlatform.system}.lazydotnet
        ];

        file = {
          ".config/lazydotnet/settings.json".text = builtins.toJSON {
            "$schema" = "https://raw.githubusercontent.com/ckob/lazydotnet/main/docs/settings.schema.json";
            DetailsPane = {
              ReferencesTab = {
                Enabled = true;
                Position = 0;
              };
              NuGetsTab = {
                Enabled = true;
                Position = 1;
              };
              TestsTab = {
                Enabled = true;
                Position = 2;
              };
              ExecutionTab = {
                Enabled = true;
                Position = 3;
              };
            };
          };
        };
      };
    };
}
