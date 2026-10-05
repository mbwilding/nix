{ ... }:

{
  flake.modules.nixos.gui =
    { lib, ... }:
    {
      key = "gui";

      options.host.gui.enable = lib.mkEnableOption "a graphical session on this host";
    };
}
