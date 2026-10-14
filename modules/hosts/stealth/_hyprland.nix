{ lib, ... }:

{
  wayland.windowManager.hyprland = {
    settings = {
      monitor = lib.mkAfter [
        # Internal
        {
          # output = "eDP-1";
          output = "desc:Samsung Display Corp. 0x41B8";
          mode = "2560x1600@240.00000";
          position = "0x0";
          scale = 1.0;
          transform = 0;
          bitdepth = 10;
          supports_wide_color = 1;
          supports_hdr = 1;
        }
      ];

      workspace_rule = lib.mkAfter [
        {
          workspace = 1;
          monitor = "desc:Samsung Display Corp. 0x41B8";
          persistent = true;
          default = true;
        }
        {
          workspace = 2;
          monitor = "desc:Samsung Display Corp. 0x41B8";
          persistent = true;
        }
        {
          workspace = 3;
          monitor = "desc:Samsung Display Corp. 0x41B8";
          persistent = true;
        }
        {
          workspace = 4;
          monitor = "desc:Samsung Display Corp. 0x41B8";
          persistent = true;
        }
        {
          workspace = 5;
          monitor = "desc:Samsung Display Corp. 0x41B8";
          persistent = true;
        }
      ];
    };
  };

  services.hypridle = {
    settings = {
      listener = [
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
