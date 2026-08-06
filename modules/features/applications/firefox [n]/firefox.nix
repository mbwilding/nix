{ ... }:

{
  flake.modules.homeManager.firefox =
    { pkgs, ... }:
    {
      programs.firefox = {
        enable = true;
        package = pkgs.firefox;
        configPath = ".mozilla/firefox";

        policies = {
          Preferences = {
            "browser.ml.enable" = {
              Value = false;
              Status = "locked";
            };
          };
        };
      };
    };
}
