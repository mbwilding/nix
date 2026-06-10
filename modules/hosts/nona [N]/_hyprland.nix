{ lib, ... }:

let
  cursorSize = 48;
in
{
  wayland.windowManager.hyprland.settings = {
    monitorv2 = [
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

    workspace = [
      "1, monitor:desc:Lenovo Group Limited 0x8AC2, layoutopt:direction:right, persistent:true, default:true"
      "2, monitor:desc:Lenovo Group Limited 0x8AC2, layoutopt:direction:right, persistent:true"
      "3, monitor:desc:Lenovo Group Limited 0x8AC2, layoutopt:direction:right, persistent:true"
      "4, monitor:desc:Lenovo Group Limited 0x8AC2, layoutopt:direction:right, persistent:true"
      "5, monitor:desc:Lenovo Group Limited 0x8AC2, layoutopt:direction:right, persistent:true"
    ];

    env = lib.mkAfter [
      "XCURSOR_SIZE,${toString cursorSize}"
      "HYPRCURSOR_SIZE,${toString cursorSize}"
    ];

    exec-once = lib.mkAfter [
      "brightnessctl set --device=platform::micmute 0"
      "hyprctl dispatch workspace 1"
    ];
  };
}
