{
  pkgs,
  hostname,
  ...
}:

let
  font = "NeoSpleen Nerd Font";
  anim_speed = 2.0;
  gaps = 10.0;

  anim_speed_str = builtins.toString anim_speed;

  monitors = {
    anon = [
      {
        output = "desc:LG Electronics LG TV SSCR2 0x01010101";
        mode = "3840x2160@119.88";
        position = "0x0";
        scale = 1.0;
        transform = 0;
        vrr = 2;
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
        vrr = 2;
      }
      {
        output = "desc:LG Electronics LG ULTRAWIDE 0x01010101";
        mode = "2560x1080@60";
        position = "-1080x0";
        scale = 1.0;
        transform = 3;
      }
    ];

    nona = [
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
  };
in
{
  home = {
    packages = with pkgs; [
      hyprshot
      hyprnotify
      kdePackages.breeze
      kdePackages.plasma-integration
      pulseaudio
    ];

    file.".local/state/caelestia/scheme.json".text = builtins.toJSON {
      name = "gronk";
      flavour = "default";
      mode = "dark";
      variant = "tonalspot";
      colours = {
        primary_paletteKeyColor = "4eade5";
        secondary_paletteKeyColor = "6c95eb";
        tertiary_paletteKeyColor = "9591ff";
        neutral_paletteKeyColor = "787878";
        neutral_variant_paletteKeyColor = "a4a4a4";
        background = "000000";
        onBackground = "bdbdbd";
        surface = "000000";
        surfaceDim = "202020";
        surfaceBright = "404040";
        surfaceContainerLowest = "101010";
        surfaceContainerLow = "181818";
        surfaceContainer = "202020";
        surfaceContainerHigh = "303030";
        surfaceContainerHighest = "404040";
        onSurface = "bdbdbd";
        surfaceVariant = "4f5258";
        onSurfaceVariant = "a4a4a4";
        inverseSurface = "bdbdbd";
        inverseOnSurface = "202020";
        outline = "787878";
        outlineVariant = "4f5258";
        shadow = "000000";
        scrim = "000000";
        surfaceTint = "4eade5";
        primary = "4eade5";
        onPrimary = "000000";
        primaryContainer = "6c95eb";
        onPrimaryContainer = "000000";
        inversePrimary = "4eade5";
        secondary = "6c95eb";
        onSecondary = "000000";
        secondaryContainer = "6c95eb";
        onSecondaryContainer = "000000";
        tertiary = "9591ff";
        onTertiary = "000000";
        tertiaryContainer = "9591ff";
        onTertiaryContainer = "000000";
        error = "ff4747";
        onError = "000000";
        errorContainer = "ff4747";
        onErrorContainer = "ff4747";
        primaryFixed = "4eade5";
        primaryFixedDim = "4eade5";
        onPrimaryFixed = "000000";
        onPrimaryFixedVariant = "000000";
        secondaryFixed = "6c95eb";
        secondaryFixedDim = "6c95eb";
        onSecondaryFixed = "000000";
        onSecondaryFixedVariant = "000000";
        tertiaryFixed = "e2bfff";
        tertiaryFixedDim = "9591ff";
        onTertiaryFixed = "000000";
        onTertiaryFixedVariant = "000000";
        term0 = "181818";
        term1 = "E78284";
        term2 = "39CC84";
        term3 = "C9A26D";
        term4 = "8CAAEE";
        term5 = "F4B8E4";
        term6 = "81C8BE";
        term7 = "A5ADCE";
        term8 = "4F5258";
        term9 = "FF4747";
        term10 = "39CC8F";
        term11 = "FFFFFF";
        term12 = "9591FF";
        term13 = "ED94C0";
        term14 = "5ABFB5";
        term15 = "B5BFE2";
        rosewater = "edeecf";
        flamingo = "e2bfff";
        pink = "ed94c0";
        mauve = "9591ff";
        red = "ed94c0";
        maroon = "ffc794";
        peach = "ffb083";
        yellow = "c9a26d";
        green = "85c46c";
        teal = "83f1ff";
        sky = "83f1ff";
        sapphire = "66c3cc";
        blue = "4eade5";
        lavender = "c191ff";
        klink = "4eade5";
        klinkSelection = "4eade5";
        kvisited = "6c95eb";
        kvisitedSelection = "6c95eb";
        knegative = "ff4747";
        knegativeSelection = "ff4747";
        kneutral = "ffb083";
        kneutralSelection = "ffb083";
        kpositive = "39cc8f";
        kpositiveSelection = "39cc8f";
        text = "bdbdbd";
        subtext1 = "a4a4a4";
        subtext0 = "787878";
        overlay2 = "4f5258";
        overlay1 = "404040";
        overlay0 = "303030";
        surface2 = "404040";
        surface1 = "303030";
        surface0 = "202020";
        base = "101010";
        mantle = "101010";
        crust = "0a0a0a";
        success = "39cc8f";
        onSuccess = "000000";
        successContainer = "39cc8f";
        onSuccessContainer = "000000";
      };
    };

    file.".config/kdeglobals".text = ''
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

    file.".config/dolphinrc".text = ''
      [General]
      PreviewsShown=true

      [PreviewSettings]
      Plugins=appimagethumbnail,audiothumbnail,blenderthumbnail,comicbookthumbnail,cursorthumbnail,directorythumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,ffmpegthumbs,gsthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,mobithumbnail,opendocumentthumbnail,rawthumbnail,svgthumbnail,textthumbnail,windowsexethumbnail,windowsimagethumbnail
    '';
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    systemd.variables = [ "--all" ];
    importantPrefixes = [
      "$mod"
      "output"
      "name"
    ];
    settings = {
      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      general = {
        layout = "scrolling"; # dwindle

        gaps_in = gaps;
        gaps_out = gaps * 2;
        border_size = 0;

        # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
        "col.active_border" = "rgba(4eade5ee)";
        "col.inactive_border" = "rgba(787878ee)";

        # Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true;

        # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        allow_tearing = false;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      debug = {
        full_cm_proto = false;
      };

      # https://wiki.hyprland.org/Configuring/Variables/#decoration
      decoration = {
        rounding = 10;

        # Change transparency of focused and unfocused windows
        active_opacity = 1.0;
        inactive_opacity = 0.7;

        shadow = {
          enabled = false;
        };

        # https://wiki.hyprland.org/Configuring/Variables/#blur
        blur = {
          enabled = false;
          size = 3;
          passes = 1;

          vibrancy = 0.1696;
        };
      };

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        background_color = "0x000000";
        vfr = true;
      };

      render = {
        send_content_type = true;
        direct_scanout = 1;
        cm_fs_passthrough = 2;
        cm_auto_hdr = 2;
        new_render_scheduling = false;
      };

      exec-once = [
        "systemctl --user start hyprpolkitagent"
        "hyprnotify"
        # "nm-applet"
        # "hyprpaper"
        # "hyprpanel"
        # "hypridle"
      ]
      ++ (
        if hostname == "anon" then
          [
            "hyprctl dispatch workspace name:social"
            "hyprctl dispatch workspace name:spare"
            "hyprctl dispatch workspace name:main"
          ]
        else
          [
            "hyprctl dispatch workspace main"
            "brightnessctl set --device=platform::micmute 0"
          ]
      );

      "$mod" = "SUPER";
      bind = [
        "$mod, B, exec, google-chrome"
        "$mod, E, exec, dolphin"
        "$mod, N, exec, neovide"
        "$mod, P, exec, 1password"
        "$mod, R, exec, wofi --show drun"
        "$mod, T, exec, ghostty"
        "$mod, C, exec, ghostty -e btop"
        "$mod, S, exec, spotify"
        "$mod, M, exec, teams-for-linux"
        "$mod, D, exec, discord"

        "$mod, F, togglefloating,"
        "$mod, O, fullscreen,"
        "$mod, Q, killactive,"
        # "$mod, Z, exec, hyprlock,"
        "$mod, grave, exit,"
        "$mod, semicolon, exec, hyprshot -m window -m active --clipboard-only"
        "$mod, Z, exec, hyprshot -m window -m active"

        # Switch window focus
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        # Swap window positions
        "$mod SHIFT, h, swapwindow, l"
        "$mod SHIFT, l, swapwindow, r"
        "$mod SHIFT, k, swapwindow, u"
        "$mod SHIFT, j, swapwindow, d"

        ", Print, exec, hyprshot -m window -m active"

        # Scroll through existing workspaces with mod + scroll
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # Media keys
        ", XF86AudioMute,    exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle"

        # Move active window to a workspace
      ]
      ++ (builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = i + 1;
          in
          [
            "$mod, code:1${toString i}, workspace, ${toString ws}"
            "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
          ]
        ) 9
      ));

      binde = [
        # Media keys
        ", XF86AudioLowerVolume,  exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioRaiseVolume,  exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", 248,                   exec, brightnessctl set --device=platform::kbd_backlight 5%-"
        ", XF86Calculator,        exec, brightnessctl set --device=platform::kbd_backlight 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp,   exec, brightnessctl set +5%"
      ];

      bindm = [
        # Move/resize windows with mod + LMB/RMB and dragging
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      animations = {
        enabled = true;
        animation = [
          "windows, 1, ${anim_speed_str}, default"
          "layers, 1, ${anim_speed_str}, default"
          "fade, 1, ${anim_speed_str}, default"
          "border, 1, ${anim_speed_str}, default"
          "borderangle, 1, ${anim_speed_str}, default"
          "workspaces, 1, ${anim_speed_str}, default"
          "zoomFactor, 1, ${anim_speed_str}, default"
          "monitorAdded, 1, ${anim_speed_str}, default"
        ];
      };

      xwayland = {
        force_zero_scaling = true;
      };

      monitorv2 = monitors.${hostname} or [ ];

      input = {
        kb_layout = "us";
        kb_variant = "dvorak";

        resolve_binds_by_sym = true;

        repeat_rate = 63;
        repeat_delay = 195;

        sensitivity = 0;
        force_no_accel = 1;
        numlock_by_default = false;
        follow_mouse = 0;
        mouse_refocus = false;

        touchpad = {
          natural_scroll = true;
          scroll_factor = 1.0;
        };
      };

      device = [
        {
          name = "dygma-defy-keyboard";
          kb_layout = "us";
          kb_variant = "us";
        }
        {
          name = "cornemini-keyboard";
          kb_layout = "us";
          kb_variant = "us";
        }
        {
          name = "zsa-technology-labs-voyager";
          kb_layout = "us";
          kb_variant = "us";
        }
      ];

      gestures = {
        workspace_swipe_create_new = true;
        workspace_swipe_forever = true;
        workspace_swipe_touch = true;
        # workspace_swipe_min_speed_to_force = 0;

        gesture = [
          # "3, up, fullscreen"
          # "3, horizontal, workspace"
          "3, vertical, workspace"
          "3, right, dispatcher, layoutmsg, focus left"
          "3, left, dispatcher, layoutmsg, focus right"
          "3, pinchin, dispatcher, layoutmsg, colresize +conf"
          "3, pinchout, dispatcher, layoutmsg, colresize -conf"
        ];
      };

      # https://wiki.hypr.land/Configuring/Variables/#cursor
      cursor = {
        no_hardware_cursors = 2;
        no_break_fs_vrr = 2;
        hide_on_key_press = true;
        hide_on_touch = true;
        no_warps = false;
      };

      env = [
        "CLUTTER_BACKEND,wayland"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "GDK_BACKEND,wayland,x11,*"
        "GTK_THEME,Breeze-Dark"
        "HYPRCURSOR_SIZE,24"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_QPA_PLATFORMTHEME,kde"
        "SDL_VIDEODRIVER,wayland"
        "GDK_SCALE,1"
        "XCURSOR_SIZE,24"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "HYPRSHOT_DIR,/home/anon/Pictures/Screenshots"
      ];

      scrolling = {
        fullscreen_on_one_column = true;
        follow_focus = true;
        direction = "right";
      };

      workspace =
        if hostname == "anon" then
          [
            "name:main, monitor:desc:LG Electronics LG TV SSCR2 0x01010101, default:true, layoutopt:direction:right, persistent:true"
            "name:social, monitor:desc:Dell Inc. Dell AW3418DW, default:true, layoutopt:direction:down, persistent:true"
            "name:spare, monitor:desc:LG Electronics LG ULTRAWIDE 0x01010101, default:true, layoutopt:direction:down, persistent:true"
          ]
        else if hostname == "nona" then
          [
            "name:main, monitor:desc:Lenovo Group Limited 0x8AC2, default:true, layoutopt:direction:right, persistent:true"
          ]
        else
          [ ];

      windowrule = [
        {
          name = "Game";
          tile = 0;
          "match:content" = 3;
        }
        {
          name = "Modals";
          float = 1;
          tile = 0;
          "match:modal" = true;
        }
        {
          name = "Proton";
          tile = 0;
          "match:xdg_tag" = "proton-game";
        }
        {
          name = "SuppressMaximize";
          suppress_event = "maximize";
          "match:class" = ".*";
        }
        {
          name = "IdleInhibitFullscreen";
          idle_inhibit = "fullscreen";
          "match:class" = ".*";
        }
        {
          name = "UnrealEngine";
          workspace = "name:main";
          no_anim = "on";
          no_initial_focus = "on";
          "match:class" = "^(UnrealEditor)$";
          "match:title" = "^\w*$";
        }
      ]
      ++ (
        if hostname == "anon" then
          [
            {
              name = "Teams";
              workspace = "name:social";
              "match:class" = "teams-for-linux";
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
          ]
        else
          [ ]
      );
    };
  };

  gtk = {
    enable = true;

    font = {
      name = font;
      size = 10;
    };

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
      size = 24;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  xdg = {
    configFile."gtk-4.0/gtk.css".force = true;

    mimeApps = {
      enable = true;
      defaultApplications = {
        "image/png" = "org.kde.gwenview.desktop";
        "image/jpeg" = "org.kde.gwenview.desktop";
        "image/gif" = "org.kde.gwenview.desktop";
        "image/bmp" = "org.kde.gwenview.desktop";
        "image/svg+xml" = "org.kde.gwenview.desktop";
        "image/tiff" = "org.kde.gwenview.desktop";
        "image/webp" = "org.kde.gwenview.desktop";
        "image/x-icon" = "org.kde.gwenview.desktop";
      };
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Breeze-Dark";
      icon-theme = "breeze-dark";
      cursor-theme = "Breeze";
      cursor-size = 24;
    };
  };

  programs = {
    wofi = {
      enable = true;
      settings = {
        mode = "drun";
        allow_images = true;
        prompt = "Search";
        location = "top_center";
        height = "30%";
        width = "20%";
      };
      style = ''
        * {
            font-family: "${font}";
            font-size: 22px;
        }

        image {
            margin-left: 0.5em;
            margin-right: 0.5em;
        }
      '';

    };
  };
}
