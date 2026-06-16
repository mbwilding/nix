{ lib, ... }:

{
  wayland.windowManager.hyprland = {
    settings = {
      monitor = lib.mkAfter [
        # Internal
        {
          output = "desc:Lenovo Group Limited 0x8AC2";
          mode = "2944x1840@90";
          position = "0x0";
          scale = 1.33;
          transform = 0;
          bitdepth = 10;
          supports_wide_color = 1;
          supports_hdr = 1;
        }
        # Home
        {
          output = "HDMI-A-1";
          mode = "3840x2160@120.00";
          position = "1080x-1080";
          scale = 2.0;
          transform = 0;
          bitdepth = 10;
          supports_wide_color = 1;
          supports_hdr = 1;
        }
        # Work
        {
          output = "DP-7";
          mode = "2560x1440@74.97";
          position = "-1280x-1440";
          scale = 1.0;
          transform = 0;
        }
        {
          output = "DP-6";
          mode = "2560x1440@74.97";
          position = "1280x-1440";
          scale = 1.0;
          transform = 0;
        }
      ];

      workspace_rule = lib.mkAfter [
        {
          workspace = 1;
          monitor = "desc:Lenovo Group Limited 0x8AC2";
          persistent = true;
          default = true;
        }
        {
          workspace = 2;
          monitor = "desc:Lenovo Group Limited 0x8AC2";
          persistent = true;
        }
        {
          workspace = 3;
          monitor = "desc:Lenovo Group Limited 0x8AC2";
          persistent = true;
        }
        {
          workspace = 4;
          monitor = "desc:Lenovo Group Limited 0x8AC2";
          persistent = true;
        }
        {
          workspace = 5;
          monitor = "desc:Lenovo Group Limited 0x8AC2";
          persistent = true;
        }
      ];
    };

    extraConfig = lib.mkAfter ''
      hl.on("hyprland.start", function()
        hl.exec_cmd("brightnessctl set --device=platform::micmute 0")
        hl.exec_cmd("hyprctl dispatch workspace 1")
      end)

      hl.bind(mod .. " + backslash", function()
        hl.exec_cmd("systemctl is-active --quiet keyd && systemctl stop keyd || systemctl start keyd")
      end)
    '';
  };
}
