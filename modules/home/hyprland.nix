{
  pkgs,
  hostname,
  ...
}:

let
  anim_speed = 2.0;
  gaps = 10.0;

  anim_speed_str = builtins.toString anim_speed;

  monitors = {
    anon = [
      {
        output = "HDMI-A-1";
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
        output = "DP-2";
        mode = "3440x1440@120";
        position = "3840x-720";
        scale = 1.0;
        transform = 1;
        vrr = 2;
      }
      # {
      #   output = "DP-4";
      #   mode = "2560x1080@60";
      #   position = "-1080x0";
      #   scale = 1.0;
      #   transform = 3;
      # }
    ];

    nona = [
      # Internal
      {
        output = "eDP-1";
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
      pulseaudio
      hyprlandPlugins.hyprscrolling
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = [ "--all" ];
    # portalPackage = null;
    importantPrefixes = [
      "$mod"
      "output"
      "name"
    ];
    plugins = [
      pkgs.hyprlandPlugins.hyprscrolling
    ];
    settings = {
      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      general = {
        # dwindle
        layout = "scrolling";

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
        cm_fs_passthrough = 0;
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

        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"
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
        follow_mouse = 0;
        mouse_refocus = false;

        touchpad = {
          natural_scroll = true;
          scroll_factor = 1.0;
        };
      };

      device = [
        {
          name = "keyd-virtual-keyboard";
          kb_layout = "us";
          kb_variant = "dvorak";
        }
        {
          name = "at-translated-set-2-keyboard";
          kb_layout = "us";
          kb_variant = "dvorak";
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
          "3, horizontal, workspace"
          "3, up, fullscreen"
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

      plugin = {
        hyprscrolling = {
          fullscreen_on_one_column = true;
        };
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

      windowrule =
        if hostname == "anon" then
          [
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
          [ ];
    };
  };

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
      size = 24;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
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
        image {
            margin-left: 0.5em;
            margin-right: 0.5em;
        }
      '';
    };

    caelestia = {
      enable = true;
      systemd = {
        enable = true; # if you prefer starting from your compositor
        target = "graphical-session.target";
        environment = [ ];
      };
      settings = {
        bar = {
          status = {
            showBattery = hostname == "nona";
          };
        };
        launcher = {
          vimKeybinds = true;
        };
        paths.wallpaper = null;
        wallpaper.color = "#000000";
        # paths.wallpaperDir = "~/Images";
      };
      cli = {
        enable = true; # Also add caelestia-cli to path
        settings = {
          theme.enableGtk = true;
        };
      };
    };

    # hyprpanel = {
    #   enable = false;
    #   # Configure and theme almost all options from the GUI.
    #   # See 'https://hyprpanel.com/configuration/settings.html'.
    #   # Default: <same as gui>
    #
    #   settings = {
    #
    #     # Configure bar layouts for monitors.
    #     # See 'https://hyprpanel.com/configuration/panel.html'.
    #     # Default: null
    #     # layout = {
    #     #   bar.autoHide = "single-window";
    #     #   theme = {
    #     #     bar = {
    #     #       border.location = "none";
    #     #       enableShadow = false;
    #     #       buttons = {
    #     #         enableBorders = false;
    #     #         windowtitle.enableBorder = false;
    #     #       };
    #     #     };
    #     #   };
    #     #   bar = {
    #     #     network = {
    #     #       label = true;
    #     #       showWifiInfo = true;
    #     #     };
    #     #     clock.showTime = true;
    #     #     layouts = {
    #     #       "*" = {
    #     #         left = [
    #     #           # "dashboard"
    #     #           "workspaces"
    #     #           "windowtitle"
    #     #         ];
    #     #         middle = [ "media" ];
    #     #         right = [
    #     #           "cpu"
    #     #           "ram"
    #     #           "volume"
    #     #           "network"
    #     #           "bluetooth"
    #     #           "battery"
    #     #           "systray"
    #     #           "clock"
    #     #           "notifications"
    #     #         ];
    #     #       };
    #     #     };
    #     #   };
    #     # };
    #
    #     bar.launcher.autoDetectIcon = true;
    #     bar.workspaces.show_icons = true;
    #
    #     menus.clock = {
    #       time = {
    #         military = true;
    #         hideSeconds = false;
    #       };
    #       weather.unit = "metric";
    #     };
    #
    #     menus.dashboard.directories.enabled = false;
    #     menus.dashboard.stats.enable_gpu = true;
    #
    #     theme.bar.transparent = true;
    #
    #     theme.font = {
    #       name = "NeoSpleen Nerd Font";
    #       size = "20px";
    #     };
    #   };
    # };
  };
}
