{ ... }:

{
  flake.modules.homeManager.theme =
    {
      pkgs,
      lib,
      hostname,
      ...
    }:
    let
      cursor_size = if hostname == "anon" then 16 else 24;
    in
    {
      gtk = {
        enable = true;

        theme = {
          package = pkgs.kdePackages.breeze-gtk;
          name = "Breeze-Dark";
        };

        iconTheme = {
          package = pkgs.kdePackages.breeze-icons;
          name = "breeze-dark";
        };

        cursorTheme = {
          name = "Breeze";
          size = cursor_size;
        };

        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };

        gtk4.theme = null;
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
      };

      dconf = {
        enable = hostname != "wsl";
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Breeze-Dark";
            icon-theme = "breeze-dark";
            cursor-theme = "Breeze";
            cursor-size = cursor_size;
          };
        };
      };

      home.file.".config/kdeglobals".text = ''
        [General]
        ColorScheme=BreezeDark
        Name=Breeze Dark
        shadeSortColumn=true
        widgetStyle=Breeze
        TerminalApplication=ghostty
        TerminalService=com.mitchellh.ghostty.desktop

        [Icons]
        Theme=breeze-dark

        [KDE]
        LookAndFeelPackage=org.kde.breezedark.desktop
        SingleClick=false
        widgetStyle=Breeze

        [Colors:View]
        BackgroundAlternate=49,54,59
        BackgroundNormal=35,38,41
        DecorationFocus=61,174,233
        DecorationHover=61,174,233
        ForegroundActive=61,174,233
        ForegroundInactive=161,169,177
        ForegroundLink=29,153,243
        ForegroundNegative=218,68,83
        ForegroundNeutral=246,116,0
        ForegroundNormal=239,240,241
        ForegroundPositive=39,174,96
        ForegroundVisited=155,89,182

        [Colors:Window]
        BackgroundAlternate=49,54,59
        BackgroundNormal=49,54,59
        DecorationFocus=61,174,233
        DecorationHover=61,174,233
        ForegroundActive=61,174,233
        ForegroundInactive=161,169,177
        ForegroundLink=29,153,243
        ForegroundNegative=218,68,83
        ForegroundNeutral=246,116,0
        ForegroundNormal=239,240,241
        ForegroundPositive=39,174,96
        ForegroundVisited=155,89,182

        [Colors:Button]
        BackgroundAlternate=49,54,59
        BackgroundNormal=49,54,59
        DecorationFocus=61,174,233
        DecorationHover=61,174,233
        ForegroundActive=61,174,233
        ForegroundInactive=161,169,177
        ForegroundLink=29,153,243
        ForegroundNegative=218,68,83
        ForegroundNeutral=246,116,0
        ForegroundNormal=239,240,241
        ForegroundPositive=39,174,96
        ForegroundVisited=155,89,182

        [Colors:Selection]
        BackgroundAlternate=29,153,243
        BackgroundNormal=61,174,233
        DecorationFocus=61,174,233
        DecorationHover=61,174,233
        ForegroundActive=252,252,252
        ForegroundInactive=161,169,177
        ForegroundLink=253,188,75
        ForegroundNegative=218,68,83
        ForegroundNeutral=246,116,0
        ForegroundNormal=252,252,252
        ForegroundPositive=39,174,96
        ForegroundVisited=155,89,182

        [Colors:Tooltip]
        BackgroundAlternate=49,54,59
        BackgroundNormal=49,54,59
        DecorationFocus=61,174,233
        DecorationHover=61,174,233
        ForegroundActive=61,174,233
        ForegroundInactive=161,169,177
        ForegroundLink=29,153,243
        ForegroundNegative=218,68,83
        ForegroundNeutral=246,116,0
        ForegroundNormal=239,240,241
        ForegroundPositive=39,174,96
        ForegroundVisited=155,89,182

        [Colors:Complementary]
        BackgroundAlternate=49,54,59
        BackgroundNormal=42,46,50
        DecorationFocus=61,174,233
        DecorationHover=61,174,233
        ForegroundActive=61,174,233
        ForegroundInactive=161,169,177
        ForegroundLink=29,153,243
        ForegroundNegative=218,68,83
        ForegroundNeutral=246,116,0
        ForegroundNormal=239,240,241
        ForegroundPositive=39,174,96
        ForegroundVisited=155,89,182
      '';
    };
}
