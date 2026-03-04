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
        "brightnessctl set --device=platform::micmute 0"
        "systemctl --user start hyprpolkitagent"
        # "nm-applet"
        # "hyprpaper"
        # "hyprpanel"
        # "hypridle"
        "hyprctl dispatch workspace main"
      ];

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
        "$mod, Z, exec, hyprlock,"
        "$mod, grave, exit,"
        "$mod, semicolon, exec, hyprshot -m window -m active --clipboard-only"

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
        kb_variant = if hostname == "anon" then "us" else "dvorak";

        resolve_binds_by_sym = true;

        repeat_rate = 63;
        repeat_delay = 195;

        sensitivity = 0;
        force_no_accel = 1;
        numlock_by_default = true;
        follow_mouse = 0;
        mouse_refocus = false;

        touchpad = {
          natural_scroll = true;
          scroll_factor = 1.0;
        };
      };

      device = [
        # Dygma Defy (DVORAK mapped to QWERTY)
        {
          name = "dygma-defy-keyboard";
          kb_layout = "us";
          kb_variant = "us";
        }
        # Laptop Keyboard
        {
          name = "at-translated-set-2-keyboard";
          kb_layout = "us";
          kb_variant = "dvorak";
        }
        # Laptop Keyd
        {
          name = "keyd-virtual-keyboard";
          kb_layout = "us";
          kb_variant = "dvorak";
        }
        # Corne Mini 34-key
        {
          name = "cornemini-keyboard";
          kb_layout = "us";
          kb_variant = "us";
        }
        # ZSA Voyager
        {
          name = "zsa-technology-labs-voyager";
          kb_layout = "us";
          kb_variant = "us";
        }
        # Sara's keyboard
        {
          name = "holtek-usb-hid-keyboard";
          kb_layout = "us";
          kb_variant = "dvorak";
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
      ];

      scrolling = {
          fullscreen_on_one_column = true;
          follow_focus = true;
          direction = "right";
      };

      workspace =
        if hostname == "anon" then
          [
            "defaultName:Main,   name:main,   monitor:HDMI-A-1, default:true, layoutopt:orientation:left, persistent:true"
            "defaultName:Social, name:social, monitor:DP-2,     default:true, layoutopt:orientation:top,  persistent:true"
            # "defaultName:Spare,  name:spare,  monitor:DP-5,     default:true, layoutopt:orientation:top,  persistent:true"
          ]
        else if hostname == "nona" then
          [
            "defaultName:Main,   name:main,   monitor:eDP-1, default:true, layoutopt:orientation:left, persistent:true"
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
          workspace = "main";
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
              workspace = "social";
              "match:class" = "teams-for-linux";
            }
            {
              name = "Spotify";
              workspace = "social";
              "match:class" = "spotify";
            }
            {
              name = "Discord";
              workspace = "social";
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

    caelestia = {
      enable = true;
      systemd = {
        enable = true;
        target = "graphical-session.target";
        environment = [ ];
      };
      settings = {
        general = {
          apps = {
            terminal = [ "ghostty" ];
            audio = [ "pavucontrol" ];
            playback = [ "mpv" ];
            explorer = [ "dolphin" ];
          };

          idle = {
            lockBeforeSleep = true;
            inhibitWhenAudio = true;
            timeouts = [
              {
                timeout = 180;
                idleAction = "lock";
              }
              {
                timeout = 300;
                idleAction = "dpms off";
                returnAction = "dpms on";
              }
              {
                timeout = 600;
                idleAction = [
                  "systemctl"
                  "suspend-then-hibernate"
                ];
              }
            ];
          };

          battery = {
            criticalLevel = 3;
            warnLevels = [
              {
                level = 20;
                title = "Battery Level Low";
                message = "Please connect your device to a power source at your earliest convenience.";
                icon = "battery_android_frame_2";
              }
              {
                level = 10;
                title = "Battery Level Critically Low";
                message = "Immediate connection to a power source is strongly recommended.";
                icon = "battery_android_frame_1";
              }
              {
                level = 5;
                title = "Battery Level Critical";
                message = "System shutdown is imminent. Please connect to a power source immediately.";
                icon = "battery_android_alert";
                critical = true;
              }
            ];
          };
        };

        background = {
          enabled = false;
          wallpaperEnabled = false;

          desktopClock = {
            enabled = false;
            scale = 1.0;
            position = "bottom-right";
            invertColors = false;

            background = {
              enabled = false;
              opacity = 0.7;
              blur = true;
            };

            shadow = {
              enabled = true;
              opacity = 0.7;
              blur = 0.4;
            };
          };

          visualiser = {
            enabled = true;
            autoHide = true;
            blur = false;
            rounding = 1;
            spacing = 1;
          };
        };

        bar = {
          persistent = false;
          showOnHover = true;
          dragThreshold = 1;

          # excludedScreens = [
          #   "DP-1"
          #   "DP-2"
          #   "DP-3"
          #   "DP-4"
          #   "DP-5"
          # ];

          entries = [
            {
              id = "logo";
              enabled = true;
            }
            {
              id = "workspaces";
              enabled = true;
            }
            {
              id = "spacer";
              enabled = true;
            }
            {
              id = "activeWindow";
              enabled = true;
            }
            {
              id = "spacer";
              enabled = true;
            }
            {
              id = "tray";
              enabled = true;
            }
            {
              id = "statusIcons";
              enabled = true;
            }
            {
              id = "clock";
              enabled = true;
            }
            {
              id = "power";
              enabled = true;
            }
          ];

          scrollActions = {
            workspaces = true;
            volume = true;
            brightness = true;
          };

          popouts = {
            activeWindow = false;
            tray = true;
            statusIcons = true;
          };

          workspaces = {
            shown = 0;
            activeIndicator = true;
            occupiedBg = false;
            showWindows = false; # Icons
            showWindowsOnSpecialWorkspaces = true;
            activeTrail = true; # Trailing animation on active indicator
            perMonitorWorkspaces = true;
            label = "  ";
            occupiedLabel = "󰮯";
            activeLabel = "󰮯";
            capitalisation = "preserve"; # "upper" | "lower" | "preserve"

            # list of objects: { name = string; icon = string; }
            # Override the icon for a named special workspace.
            specialWorkspaceIcons = [ ];
          };

          activeWindow = {
            inverted = false;
          };

          tray = {
            background = false;
            recolour = false;
            compact = true;
            iconSubs = [ ];
          };

          status = {
            showAudio = true;
            showMicrophone = false;
            showKbLayout = false;
            showNetwork = true;
            showWifi = true;
            showBluetooth = true;
            showBattery = true;
            showLockStatus = true;
          };

          clock.showIcon = false;

          sizes = {
            innerWidth = 40;
            windowPreviewSize = 400;
            trayMenuWidth = 300;
            batteryWidth = 250;
            networkWidth = 320;
            kbLayoutWidth = 320;
          };
        };

        border = {
          thickness = 1;
          rounding = 20;
        };

        dashboard = {
          enabled = true;
          showOnHover = true;
          dragThreshold = 1;

          performance = {
            showBattery = true;
            showGpu = true;
            showCpu = true;
            showMemory = true;
            showStorage = true;
            showNetwork = true;
          };

          sizes = {
            tabIndicatorHeight = 3;
            tabIndicatorSpacing = 5;
            infoWidth = 200;
            infoIconSize = 25;
            dateTimeWidth = 110;
            mediaWidth = 200;
            mediaProgressSweep = 180;
            mediaProgressThickness = 8;
            resourceProgessThickness = 10;
            weatherWidth = 250;
            mediaCoverArtSize = 150;
            mediaVisualiserSize = 80;
            resourceSize = 200;
          };
        };

        controlCenter = {
          sizes = {
            heightMult = 0.7;
            ratio = 16.0 / 9.0;
          };
        };

        launcher = {
          enabled = true;
          showOnHover = false;
          maxShown = 7;
          maxWallpapers = 9; # Odd looks better
          specialPrefix = "@";
          actionPrefix = ">";
          enableDangerousActions = true; # Shutdown/Reboot/Logout
          dragThreshold = 1;
          vimKeybinds = true;
          # favouriteApps = [ ];
          # hiddenApps = [ ]; # App IDs hidden (supports regex)

          useFuzzy = {
            apps = true;
            actions = true;
            schemes = true;
            variants = true;
            wallpapers = true;
          };

          sizes = {
            itemWidth = 600;
            itemHeight = 57;
            wallpaperWidth = 280;
            wallpaperHeight = 200;
          };

          # Custom/overridden action list.
          # Each action object:
          #   name        string
          #   icon        string        (Material icon name)
          #   description string
          #   command     list<string>  (or omit for built-in actions)
          #   enabled     bool
          #   dangerous   bool          (shows warning; requires enableDangerousActions)
          #
          # Built-in action ids (by name): Calculator, Scheme, Wallpaper, Variant,
          # Transparency (disabled by default), Random, Light, Dark,
          # Shutdown (dangerous), Reboot (dangerous), Logout (dangerous),
          # Lock, Sleep, Settings

          # actions = [ ];
        };

        notifs = {
          expire = true;
          defaultExpireTimeout = 6 * 1000;
          clearThreshold = 0.3;
          expandThreshold = 20;
          actionOnClick = true;
          groupPreviewNum = 3;
          openExpanded = true;

          sizes = {
            width = 400;
            image = 41;
            badge = 20;
          };
        };

        osd = {
          enabled = true;
          hideDelay = 750;
          enableBrightness = true;
          enableMicrophone = true;

          sizes = {
            sliderWidth = 30;
            sliderHeight = 150;
          };
        };

        session = {
          enabled = true;
          dragThreshold = 1;
          vimKeybinds = true;

          # Material icons
          icons = {
            logout = "logout";
            shutdown = "power_settings_new";
            hibernate = "downloading";
            reboot = "cached";
          };

          commands = {
            logout = [
              "loginctl"
              "terminate-user"
              ""
            ];
            shutdown = [
              "systemctl"
              "poweroff"
            ];
            hibernate = [
              "systemctl"
              "hibernate"
            ];
            reboot = [
              "systemctl"
              "reboot"
            ];
          };

          sizes = {
            button = 80;
          };
        };

        winfo = {
          sizes = {
            heightMult = 0.7;
            detailsWidth = 500;
          };
        };

        lock = {
          recolourLogo = false; # Match color scheme
          enableFprint = false; # Fingerprint authentication
          maxFprintTries = 0;

          sizes = {
            heightMult = 0.7;
            ratio = 16.0 / 9.0;
            centerWidth = 600;
          };
        };

        utilities = {
          enabled = true;
          maxToasts = 8;

          sizes = {
            width = 430;
            toastWidth = 430;
          };

          toasts = {
            configLoaded = false;
            chargingChanged = true;
            gameModeChanged = true;
            dndChanged = true;
            audioOutputChanged = true;
            audioInputChanged = true;
            capsLockChanged = true;
            numLockChanged = true;
            kbLayoutChanged = true;
            kbLimit = true;
            vpnChanged = true;
            nowPlaying = true;
          };

          vpn = {
            enabled = true;
            provider = [
              "wireguard"
              "wg-quick"
            ];
          };
        };

        sidebar = {
          enabled = true;
          dragThreshold = 1;

          sizes = {
            width = 430;
          };
        };

        services = {
          weatherLocation = ""; # "lat,long" or "" for auto-detect
          useFahrenheit = false;
          useFahrenheitPerformance = false;
          useTwelveHourClock = true;
          gpuType = ""; # "nvidia" | "amd" | "" (auto)
          visualiserBars = 45;
          audioIncrement = 0.1;
          brightnessIncrement = 0.1;
          maxVolume = 1.0;
          smartScheme = false;
          defaultPlayer = "Spotify";
          playerAliases = [
            {
              from = "com.github.th_ch.youtube_music";
              to = "YT Music";
            }
          ];
        };

        paths = {
          wallpaperDir = "~/Pictures/Wallpapers";
          sessionGif = "root:/assets/kurukuru.gif";
          mediaGif = "root:/assets/bongocat.gif";
        };

        appearance = {
          font = {
            size = {
              scale = 1.2;
            };
            family = {
              sans = font;
              mono = font;
              clock = font;
              material = "Material Symbols Rounded";
            };
          };
        };
      };

      cli = {
        enable = true;
        settings = {
          theme.enableGtk = true;
        };
      };
    };
  };
}
