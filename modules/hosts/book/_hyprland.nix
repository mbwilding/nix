{ lib, ... }:

{
  wayland.windowManager.hyprland = {
    settings = {
      monitor = lib.mkAfter [
        # Internal
        {
          output = "desc:Panasonic Industry Company TDM13O56     0x05A11100";
          mode = "3000x2000@59.98";
          position = "0x0";
          scale = 1.67;
          transform = 0;
        }
      ];
    };
  };
}
