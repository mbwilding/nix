{ lib, ... }:

{
  programs.niri.settings = {
    outputs = {
      "Lenovo Group Limited 0x8AC2 Unknown" = {
        mode = {
          width = 2944;
          height = 1840;
          refresh = 90.0;
        };
        position = {
          x = 0;
          y = 0;
        };
        scale = 1.33;
      };
      "HDMI-A-1" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 120.0;
        };
        position = {
          x = -813;
          y = -2160;
        };
        scale = 1.0;
      };
      "DP-7" = {
        mode = {
          width = 2560;
          height = 1440;
          refresh = 74.97;
        };
        position = {
          x = -1280;
          y = -1440;
        };
        scale = 1.0;
      };
      "DP-6" = {
        mode = {
          width = 2560;
          height = 1440;
          refresh = 74.97;
        };
        position = {
          x = 1280;
          y = -1440;
        };
        scale = 1.0;
      };
    };

    workspaces = {
      "1" = {
        open-on-output = "Lenovo Group Limited 0x8AC2 Unknown";
      };
      "2" = {
        open-on-output = "Lenovo Group Limited 0x8AC2 Unknown";
      };
      "3" = {
        open-on-output = "Lenovo Group Limited 0x8AC2 Unknown";
      };
      "4" = {
        open-on-output = "Lenovo Group Limited 0x8AC2 Unknown";
      };
      "5" = {
        open-on-output = "Lenovo Group Limited 0x8AC2 Unknown";
      };
    };

    spawn-at-startup = lib.mkAfter [
      {
        command = [
          "brightnessctl"
          "set"
          "--device=platform::micmute"
          "0"
        ];
      }
      {
        command = [
          "niri"
          "msg"
          "action"
          "focus-workspace"
          "1"
        ];
      }
    ];

    binds = lib.mkAfter {
      "Mod+Backslash".action.spawn = [
        "sh"
        "-c"
        "systemctl is-active --quiet keyd && systemctl stop keyd || systemctl start keyd"
      ];
    };
  };
}
