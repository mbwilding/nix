{ ... }:

let
  variantOf = keymap: if keymap == "dvorak" then "dvorak" else "";
in
{
  flake.modules.nixos.keymap =
    { lib, config, ... }:
    {
      options.host.keymap = lib.mkOption {
        type = lib.types.enum [
          "qwerty"
          "dvorak"
        ];
        default = "qwerty";
        description = "Keyboard layout for the console, X/Wayland and compositors.";
      };

      config = lib.mkIf (config.host.keymap == "dvorak") {
        console.keyMap = "dvorak";
        services.xserver.xkb.variant = "dvorak";
      };
    };

  flake.modules.homeManager.keymap =
    {
      lib,
      osConfig ? null,
      hostKeymap ? "qwerty",
      ...
    }:
    {
      options.keymap.xkbVariant = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = variantOf (if osConfig != null then osConfig.host.keymap else hostKeymap);
        description = "XKB variant derived from host.keymap.";
      };
    };
}
