{ lib, ... }:

let
  tv = {
    make = "LG Electronics";
    model = "LG TV SSCR2";
  };
  alienware = {
    make = "Dell Inc.";
    model = "Dell AW3418DW";
  };
  lg = {
    make = "LG Electronics";
    model = "LG ULTRAWIDE";
  };

  match = m: "make:${m.make},model:${m.model}";
  tagMatch = m: "monitor_make:${m.make},monitor_model:${m.model}";
  spec = m: "make:${m.make}&&model:${m.model}";

  social = "monitor:${spec alienware},tags:1";
  game = "monitor:${spec tv},tags:1,is_floating:1,vrr_only_fullscreen:1";
in
{
  wayland.windowManager.mango = {
    settings = {
      # Positive coordinates only, XWayland breaks with negative ones
      # hdr_max_lum/hdr_max_avg_lum: nix shell nixpkgs#libdisplay-info -c di-edid-decode < /sys/class/drm/card1-<output>/edid
      # (HDR Static Metadata: max luminance, max frame-average luminance)
      monitor_rule = lib.mkAfter [
        "${match tv},width:3840,height:2160,refresh:143.99,x:2560,y:720,scale:1,vrr:0,hdr:1,hdr_max_lum:1200,hdr_max_avg_lum:400,primary:1"
        "${match alienware},width:3440,height:1440,refresh:120,x:6400,y:0,scale:1,vrr:0,rr:1"
        "${match lg},width:2560,height:1080,refresh:60,x:0,y:1800,scale:1"
      ];

      tag_rule = lib.mkAfter (
        (map (n: "id:${toString n},${tagMatch tv},no_hide:1") (
          lib.range 1 5
        ))
        ++ [
          "id:1,${tagMatch alienware},layout_name:tile,master_count:99,no_hide:1"
          "id:1,${tagMatch lg},layout_name:vertical_scroller,no_hide:1"
        ]
      );

      window_rule = lib.mkAfter [
        "${social},app_id:teams-for-linux"
        "${social},app_id:[Ss]potify"
        "${social},app_id:vesktop"
        "${game},app_id:^(UnrealEditor)$"
        "${game},app_id:^(steam_app.*)$"
        "${game},app_id:^(lutris)$"
        "${game},app_id:^(battle.net|battlenet|Blizzard Battle.net)$"
        "${game},app_id:.*\\.exe$"
      ];

      exec_once = lib.mkAfter [
        "streamcontroller -b"
      ];
    };
  };
}
