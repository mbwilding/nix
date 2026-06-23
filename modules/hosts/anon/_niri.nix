{ lib, ... }:

{
  programs.niri.settings = {
    outputs = {
      "LG Electronics LG TV SSCR2 0x01010101" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 119.88;
        };
        position = {
          x = 0;
          y = 0;
        };
        scale = 1.0;
        variable-refresh-rate = true;
      };
      "Dell Inc. Dell AW3418DW #ASPlyzilYLXd" = {
        mode = {
          width = 3440;
          height = 1440;
          refresh = 120.0;
        };
        position = {
          x = 3840;
          y = -720;
        };
        scale = 1.0;
        transform.rotation = 90;
        variable-refresh-rate = true;
      };
      "LG Electronics LG ULTRAWIDE 0x01010101" = {
        mode = {
          width = 2560;
          height = 1080;
          refresh = 60.0;
        };
        position = {
          x = -1080;
          y = 0;
        };
        scale = 1.0;
        transform.rotation = 270;
      };
    };

    workspaces = {
      "1" = { open-on-output = "LG Electronics LG TV SSCR2 0x01010101"; };
      "2" = { open-on-output = "LG Electronics LG TV SSCR2 0x01010101"; };
      "3" = { open-on-output = "LG Electronics LG TV SSCR2 0x01010101"; };
      "4" = { open-on-output = "LG Electronics LG TV SSCR2 0x01010101"; };
      "5" = { open-on-output = "LG Electronics LG TV SSCR2 0x01010101"; };
      "social" = { open-on-output = "Dell Inc. Dell AW3418DW #ASPlyzilYLXd"; };
      "spare"  = { open-on-output = "LG Electronics LG ULTRAWIDE 0x01010101"; };
    };

    window-rules = [
      { matches = [{ app-id = "^(UnrealEditor)$"; }]; open-floating = true; }
      { matches = [{ app-id = "teams-for-linux"; }]; open-on-workspace = "social"; }
      { matches = [{ app-id = "Spotify"; }]; open-on-workspace = "social"; }
      { matches = [{ app-id = "vesktop"; }]; open-on-workspace = "social"; }
      { matches = [{ app-id = "^(steam)$"; }]; open-on-workspace = "1"; open-floating = true; }
      { matches = [{ app-id = "^(lutris)$"; }]; open-on-workspace = "1"; open-floating = true; }
      { matches = [{ app-id = "^(battle.net|battlenet)$"; }]; open-on-workspace = "1"; open-floating = true; }
      { matches = [{ app-id = "^(World of Warcraft|wow)$"; }]; open-on-workspace = "1"; open-floating = true; }
      { matches = [{ app-id = "^(steam_app.*)$"; }]; open-on-workspace = "1"; open-floating = true; }
    ];

    spawn-at-startup = lib.mkAfter [
      { command = [ "niri" "msg" "action" "focus-workspace" "social" ]; }
      { command = [ "niri" "msg" "action" "focus-workspace" "spare" ]; }
      { command = [ "niri" "msg" "action" "focus-workspace" "1" ]; }
      { command = [ "streamcontroller" "-b" ]; }
    ];
  };
}
