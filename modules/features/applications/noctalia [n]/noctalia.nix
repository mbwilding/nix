{ inputs, ... }:

{
  flake.modules.homeManager.noctalia =
    {
      config,
      pkgs,
      ...
    }:
    {
      programs.noctalia.package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

      home.file.".config/noctalia/palettes/gronk.json".text = builtins.toJSON {
        dark = {
          mPrimary = "#7dd3fc";
          mOnPrimary = "#00283d";
          mSecondary = "#93c5fd";
          mOnSecondary = "#0b1f33";
          mTertiary = "#a5b4fc";
          mOnTertiary = "#1e1b3a";
          mError = "#f87171";
          mOnError = "#450a0a";
          mSurface = "#000000";
          mOnSurface = "#e6e6e6";
          mSurfaceVariant = "#0d0d0d";
          mOnSurfaceVariant = "#9a9a9a";
          mOutline = "#262626";
          mShadow = "#000000";
          mHover = "#1a1a1a";
          mOnHover = "#e6e6e6";
          terminal = {
            foreground = "#e6e6e6";
            background = "#000000";
            normal = {
              black = "#1a1a1a";
              red = "#f87171";
              green = "#4ade80";
              yellow = "#facc15";
              blue = "#7dd3fc";
              magenta = "#c4b5fd";
              cyan = "#67e8f9";
              white = "#d4d4d8";
            };
            bright = {
              black = "#3f3f46";
              red = "#fca5a5";
              green = "#86efac";
              yellow = "#fde047";
              blue = "#bae6fd";
              magenta = "#ddd6fe";
              cyan = "#a5f3fc";
              white = "#f4f4f5";
            };
            cursor = "#7dd3fc";
            cursorText = "#00283d";
            selectionFg = "#e6e6e6";
            selectionBg = "#1e3a5f";
          };
        };
      };

      programs.noctalia = {
        enable = true;
        settings = {
          bar.default = {
            auto_hide = true;
            show_on_workspace_switch = false;
            reserve_space = false;
            layer = "overlay";
            position = "bottom";
            scale = 1.2;
            thickness = 38;
            padding = 18;
            widget_spacing = 18;
            margin_edge = 0;

            start = [
              "workspaces"
              "notifications"
              "session"
              "control-center"
              "wallpaper"
              "launcher"
              "clipboard"
              # "cpu"
              # "ram"
              # "temp"
              # "network_rx"
              # "network_tx"
            ];
            center = [
              "media"
            ];
            end = [
              "tray"
              "bluetooth"
              "network"
              "volume"
              "brightness"
              "battery"
              "clock"
            ];
          };

          lockscreen.blurred_desktop = true;
          dock.auto_hide = true;
          location.address = "Perth, Australia";

          weather = {
            enabled = false;
            unit = "metric";
            refresh_minutes = 30;
            effects = true;
          };

          shell = {
            font_family = "NeoSpleen Nerd Font";
            lang = "en";
            settings_show_advanced = true;
            animation.speed = 2.0;
            launch_apps_as_systemd_services = true;
            panel = {
              launcher_categories = false;
              launcher_placement = "centered";
              open_near_click_control_center = true;
              open_near_click_session = true;
              open_near_click_wallpaper = true;
              transparency_mode = "solid";
            };
          };

          theme = {
            builtin = "Tokyo-Night";
            community_palette = "GitHub Dark";
            custom_palette = "gronk";
            mode = "dark";
            source = "custom";
            templates = {
              enable_builtin_templates = false;
              enable_community_templates = false;
            };
          };

          wallpaper = {
            directory = "${config.home.homeDirectory}/nix/wallpapers";
            directory_dark = "";
            default.path = "${config.home.homeDirectory}/nix/wallpapers/scenery/chameleon-dragonfly-portrait-blurred-green-background-3840x2665-6376.jpg";
            per_monitor_directories = true;
            automation = {
              enabled = true;
              interval_seconds = 300; # 5 min
            };
          };

          widget = {
            media.max_length = 400;
            weather = {
              show_condition = true;
              max_length = 160.0;
            };
            workspaces = {
              empty_color = "on_secondary";
              hide_when_empty = true;
              labels_only_when_occupied = true;
            };
          };
        };
      };
    };
}
