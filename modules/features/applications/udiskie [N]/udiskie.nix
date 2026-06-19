{ ... }:

{
  flake.modules.nixos.udiskie =
    { ... }:
    {
      services.udisks2.enable = true;
    };

  flake.modules.homeManager.udiskie =
    { pkgs, ... }:
    {
      services.udiskie = {
        enable = true;
        automount = true;
        notify = true;
        tray = "auto";
        settings = {
          program_options = {
            file_manager = "${pkgs.ghostty}/bin/ghostty -e ${pkgs.yazi}/bin/yazi";
          };
        };
      };
    };
}
