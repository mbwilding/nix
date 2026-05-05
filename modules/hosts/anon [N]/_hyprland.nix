{ lib, ... }:

let
  cursor_size = "16";
  home = import ../../nix/_home.nix;
in
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
      "name:main, monitor:desc:LG Electronics LG TV SSCR2 0x01010101, default:true, layoutopt:direction:right, persistent:true"
      "name:social, monitor:desc:Dell Inc. Dell AW3418DW, default:true, layoutopt:direction:down, persistent:true"
      "name:spare, monitor:desc:LG Electronics LG ULTRAWIDE 0x01010101, default:true, layoutopt:direction:down, persistent:true"
    ];

    exec-once = lib.mkAfter [
      "hyprctl dispatch workspace name:social"
      "hyprctl dispatch workspace name:spare"
      "hyprctl dispatch workspace name:main"
    ];

    windowrule = lib.mkAfter [
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
        workspace = "name:main";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:class" = "^(steam)$";
      }
      {
        name = "Lutris";
        workspace = "name:main";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:class" = "^(lutris)$";
      }
      {
        name = "BattleNet";
        workspace = "name:main";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:class" = "^(battle.net|battlenet|Blizzard Battle.net)$";
      }
      {
        name = "WoW";
        workspace = "name:main";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:class" = "^(World of Warcraft|wow)$";
      }
      {
        name = "WoWTitle";
        workspace = "name:main";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:title" = "^(World of Warcraft)$";
      }
      {
        name = "GameWine";
        workspace = "name:main";
        float = "on";
        suppress_event = "fullscreen maximize";
        "match:class" = "^(steam_app.*)$";
      }
    ];

    env = lib.mkForce [
      "CLUTTER_BACKEND,wayland"
      "ELECTRON_OZONE_PLATFORM_HINT,wayland"
      "GDK_BACKEND,wayland,x11,*"
      "GTK_THEME,Breeze-Dark"
      "QT_QPA_PLATFORM,wayland;xcb"
      "QT_QPA_PLATFORMTHEME,kde"
      "SDL_VIDEODRIVER,wayland"
      "GDK_SCALE,1"
      "XDG_CURRENT_DESKTOP,Hyprland"
      "XDG_SESSION_DESKTOP,Hyprland"
      "XDG_SESSION_TYPE,wayland"
      "HYPRSHOT_DIR,${home}/Pictures/Screenshots"
      "HYPRCURSOR_SIZE,${cursor_size}"
      "XCURSOR_SIZE,${cursor_size}"
    ];
  };

  gtk.cursorTheme.size = lib.mkForce 16;
  dconf.settings."org/gnome/desktop/interface".cursor-size = lib.mkForce 16;
}
