{ lib, ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitorv2 = [
      {
        output = "desc:LG Electronics LG TV SSCR2 0x01010101";
        mode = "3840x2160@119.88";
        position = "0x0";
        scale = 1.0;
        transform = 0;
        vrr = 3;
        bitdepth = 10;
        supports_wide_color = 1;
        supports_hdr = 1;
        cm = "wide";
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
        position = "-1080x0";
        scale = 1.0;
        transform = 3;
      }
    ];

    workspace = [
      "1, monitor:desc:LG Electronics LG TV SSCR2 0x01010101, layoutopt:direction:right, persistent:true, default:true"
      "2, monitor:desc:LG Electronics LG TV SSCR2 0x01010101, layoutopt:direction:right, persistent:true"
      "3, monitor:desc:LG Electronics LG TV SSCR2 0x01010101, layoutopt:direction:right, persistent:true"
      "4, monitor:desc:LG Electronics LG TV SSCR2 0x01010101, layoutopt:direction:right, persistent:true"
      "5, monitor:desc:LG Electronics LG TV SSCR2 0x01010101, layoutopt:direction:right, persistent:true"
      "name:social, monitor:desc:Dell Inc. Dell AW3418DW #ASPlyzilYLXd,  default:true, layoutopt:direction:down, persistent:true"
      "name:spare,  monitor:desc:LG Electronics LG ULTRAWIDE 0x01010101, default:true, layoutopt:direction:down, persistent:true"
    ];

    exec-once = lib.mkAfter [
      "hyprctl dispatch workspace name:social"
      "hyprctl dispatch workspace name:spare"
      "hyprctl dispatch workspace 1"
    ];

    windowrule = lib.mkAfter [
      {
        name = "UnrealEngine";
        workspace = "1";
        float = "on";
        no_anim = "on";
        no_initial_focus = "on";
        "match:class" = "^(UnrealEditor)$";
      }
      {
        name = "Teams";
        workspace = "name:social";
        "match:title" = ".*Microsoft Teams.*";
      }
      {
        name = "Spotify";
        workspace = "name:social";
        "match:class" = "spotify";
      }
      {
        name = "Discord";
        workspace = "name:social";
        "match:class" = "discord";
      }
      {
        name = "Steam";
        workspace = "1";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:class" = "^(steam)$";
        content = "game";
      }
      {
        name = "Lutris";
        workspace = "1";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:class" = "^(lutris)$";
        content = "game";
      }
      {
        name = "BattleNet";
        workspace = "1";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:class" = "^(battle.net|battlenet|Blizzard Battle.net)$";
        content = "game";
      }
      {
        name = "WoW";
        workspace = "1";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:class" = "^(World of Warcraft|wow)$";
        content = "game";
      }
      {
        name = "WoWTitle";
        workspace = "1";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:title" = "^(World of Warcraft)$";
        content = "game";
      }
      {
        name = "GameWine";
        workspace = "1";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:class" = "^(steam_app.*)$";
        content = "game";
      }
    ];
  };
}
