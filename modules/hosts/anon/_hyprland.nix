{ lib, ... }:

{
  wayland.windowManager.hyprland = {
    settings = {
      monitor = lib.mkAfter [
        {
          output = "desc:LG Electronics LG TV SSCR2 0x01010101";
          mode = "3840x2160@143.99"; # 119.88
          position = "0x0";
          scale = 1.0;
          transform = 0;
          vrr = 3;
          bitdepth = 10;
          supports_wide_color = 1;
          supports_hdr = 1;
          cm = "wide"; # hdr, hdredid
          sdrbrightness = 1.0;
          sdrsaturation = 1.0;
          sdr_min_luminance = 0.005;
          sdr_max_luminance = 380;
          min_luminance = 0;
          max_luminance = 1200;
          max_avg_luminance = 400;
        }
        {
          output = "desc:Dell Inc. Dell AW3418DW #ASPlyzilYLXd";
          mode = "3440x1440@120";
          position = "3840x-720";
          scale = 1.0;
          transform = 1;
          vrr = 3;
        }
        {
          output = "desc:LG Electronics LG ULTRAWIDE 0x01010101";
          mode = "2560x1080@60";
          scale = 1.0;
          position = "-2560x1080";
          # position = "-1080x0";
          # transform = 3;
        }
      ];

      workspace_rule = lib.mkAfter [
        {
          workspace = 1;
          monitor = "desc:LG Electronics LG TV SSCR2 0x01010101";
          persistent = true;
          default = true;
        }
        {
          workspace = 2;
          monitor = "desc:LG Electronics LG TV SSCR2 0x01010101";
          persistent = true;
        }
        {
          workspace = 3;
          monitor = "desc:LG Electronics LG TV SSCR2 0x01010101";
          persistent = true;
        }
        {
          workspace = 4;
          monitor = "desc:LG Electronics LG TV SSCR2 0x01010101";
          persistent = true;
        }
        {
          workspace = 5;
          monitor = "desc:LG Electronics LG TV SSCR2 0x01010101";
          persistent = true;
        }
        {
          workspace = "name:social";
          monitor = "desc:Dell Inc. Dell AW3418DW #ASPlyzilYLXd";
          default = true;
          layout = "scrolling";
          layout_opts = {
            direction = "down";
          };
          persistent = true;
        }
        {
          workspace = "name:spare";
          monitor = "desc:LG Electronics LG ULTRAWIDE 0x01010101";
          default = true;
          layout = "scrolling";
          layout_opts = {
            direction = "down";
          };
          persistent = true;
        }
      ];

      window_rule = lib.mkAfter [
        {
          match = {
            class = "^(UnrealEditor)$";
          };
          workspace = "1";
          float = true;
          no_anim = true;
          no_initial_focus = true;
        }
        {
          match = {
            class = "teams-for-linux";
          };
          workspace = "name:social";
        }
        {
          match = {
            class = "[Ss]potify";
          };
          workspace = "name:social";
        }
        {
          match = {
            class = "vesktop";
          };
          workspace = "name:social";
        }
        {
          match = {
            class = "^(steam)$";
          };
          workspace = "1";
          float = true;
          suppress_event = "fullscreen maximize";
          content = "game";
        }
        {
          match = {
            class = "^(steam)$";
            title = "^(Steam)$";
          };
          float = false;
          tile = true;
        }
        {
          match = {
            class = "^(lutris)$";
          };
          workspace = "1";
          float = true;
          suppress_event = "fullscreen maximize";
          content = "game";
        }
        {
          match = {
            class = "^(battle.net|battlenet|Blizzard Battle.net)$";
          };
          workspace = "1";
          float = true;
          suppress_event = "fullscreen maximize";
          content = "game";
        }
        {
          match = {
            class = "^(steam_app.*)$";
          };
          workspace = "1";
          float = true;
          content = "game";
        }
        {
          match = {
            class = ".*\\.exe$";
          };
          workspace = "1";
          float = true;
          content = "game";
        }
      ];
    };

    extraConfig = lib.mkAfter ''
      hl.on("hyprland.start", function()
        hl.exec_cmd("hyprctl dispatch 'hl.dsp.focus({ workspace = \"name:social\" })'")
        hl.exec_cmd("hyprctl dispatch 'hl.dsp.focus({ workspace = \"name:spare\" })'")
        hl.exec_cmd("hyprctl dispatch 'hl.dsp.focus({ workspace = \"1\" })'")
        hl.exec_cmd("streamcontroller -b")
      end)
    '';
  };
}
