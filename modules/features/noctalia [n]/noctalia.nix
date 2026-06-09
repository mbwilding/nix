{ inputs, ... }:

{
  flake.modules.homeManager.noctalia =
    { config, ... }:
    {
      imports = [ inputs.noctalia.homeModules.default ];

      programs.noctalia = {
        enable = true;
        settings = {
          bar.default = {
            auto_hide = true;
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
              "weather"
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
            source = "community";
            builtin = "Tokyo-Night";
            community_palette = "Breeze";
            templates = {
              enable_builtin_templates = false;
              enable_community_templates = false;
            };
          };

          wallpaper = {
            directory = "${config.home.homeDirectory}/nix/wallpapers/retrowave";
            directory_dark = "";
            default.path = "${config.home.homeDirectory}/nix/wallpapers/retrowave/sunset-synthwave-sports-car-city-palm-trees-digital-art-4k-wallpaper-uhdpaper.com-216@1@n.jpg";
            automation = {
              enabled = true;
              interval_minutes = 3;
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
