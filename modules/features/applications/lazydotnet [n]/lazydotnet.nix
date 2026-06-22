{ inputs, pkgs, ... }:

{
  flake.modules.homeManager.lazydotnet = {
    home = {
      packages = [
        inputs.lazydotnet.packages.${pkgs.system}.lazydotnet
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
