{ ... }:

{
  flake.modules.nixos.udiskie =
    { pkgs, ... }:
    {
      services.udiskie = {
        enable = true;
        automount = true;
        notify = true;
        tray = "auto";
      };
    };
}
