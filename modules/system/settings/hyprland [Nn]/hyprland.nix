{ inputs, lib, ... }:

{
  flake.modules.nixos.hyprland =
    { pkgs, lib, ... }:
    {
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.hyprland
        inputs.self.modules.homeManager.theme
      ];

      programs = {
        hyprland = {
          enable = true;
          portalPackage = pkgs.xdg-desktop-portal-hyprland;
          xwayland.enable = true;
        };
      };

      services = {
        greetd = {
          enable = true;
          settings = {
            default_session = with pkgs; {
              command = "${tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${hyprland}/share/wayland-sessions";
              user = "greeter";
            };
          };
        };

        udisks2.enable = true;

        xserver.enable = false;
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
      };

      security = {
        rtkit.enable = true;
        polkit.enable = true;
      };

      systemd.services.greetd.serviceConfig = {
        Type = "idle";
        StandardInput = "tty";
        StandardOutput = "tty";
        StandardError = "journal";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = lib.mkForce [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk
          pkgs.kdePackages.xdg-desktop-portal-kde
        ];
        configPackages = with pkgs; [ hyprland ];
        config = {
          hyprland = {
            default = [
              "hyprland"
              "kde"
              "gtk"
            ];
            "org.freedesktop.impl.portal.FileChooser" = [
              "kde"
              "gtk"
            ];
            "org.freedesktop.impl.portal.AppChooser" = [
              "kde"
              "gtk"
            ];
          };
          common = {
            default = [
              "hyprland"
              "kde"
              "gtk"
            ];
            "org.freedesktop.impl.portal.FileChooser" = [
              "kde"
              "gtk"
            ];
            "org.freedesktop.impl.portal.AppChooser" = [
              "kde"
              "gtk"
            ];
          };
        };
      };

      environment = {
        etc."xdg/menus/applications.menu".source =
          "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

        systemPackages = with pkgs; [
          hyprpolkitagent
          kdePackages.kactivitymanagerd
          kdePackages.ark
        ];
      };
    };

  flake.modules.homeManager.hyprland =
    { pkgs, hostname, ... }:

    let
      anim_speed = 2.0;

      gaps = 10.0;
      cursor_size = if hostname == "anon" then 16 else 24;
      cursor_size_str = builtins.toString cursor_size;

      anim_speed_str = builtins.toString anim_speed;

      monitors = {
        anon = [
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
      imports = [
        ./_quickshell.nix
      ];

      home = {
        packages = with pkgs; [
          hyprshot
          jq
          # hyprnotify
          kdePackages.breeze
          kdePackages.plasma-integration
          pulseaudio
        ];

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
        systemd = {
          enable = true;
          variables = [ "--all" ];
        };
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
            layout = "master";

            gaps_in = gaps;
            gaps_out = gaps * 2;
            border_size = 0;

            "col.active_border" = "rgba(4eade5ee)";
            "col.inactive_border" = "rgba(787878ee)";

            resize_on_border = true;

            allow_tearing = false;
          };

          master = {
            mfact = 0.5;
            smart_resizing = false;
            new_status = "master";
            orientation = "right";
            center_master_fallback = "right";
            slave_count_for_center_master = 2;
          };

          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          debug = {
            full_cm_proto = false;
          };

          decoration = {
            rounding = 10;

            active_opacity = 1.0;
            inactive_opacity = 0.96;

            shadow = {
              enabled = false;
            };

            blur = {
              enabled = false;
              size = 3;
              passes = 1;

              vibrancy = 0.1696;
            };
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
            # "hyprnotify"
            # "nm-applet"
            "hyprpaper"
            # "hyprpanel"
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
            "$mod, b, exec, google-chrome"
            "$mod, e, exec, dolphin"
            "$mod, n, exec, neovide"
            "$mod, p, exec, 1password"
            "$mod, r, exec, wofi --show drun"
            "$mod, t, exec, ghostty +new-window"
            "$mod, c, exec, ghostty -e btop +new-window"
            "$mod, s, exec, spotify"
            "$mod, m, exec, teams-for-linux"
            "$mod, d, exec, discord"
            "$mod, minus, exec, ecc toggle"

            "$mod, f, togglefloating,"
            "$mod, o, fullscreen,"
            "$mod, q, killactive,"
            "$mod, grave, exit,"

            "$mod, semicolon, exec, hyprshot -m window -m active --clipboard-only"
            "$mod, apostrophe, exec, hyprshot -m region"

            # Quickshell
            "$mod, z, exec, qs ipc call lockscreen lock"
            "$mod, n, exec, qs ipc call notifications dismiss"
            "$mod, w, exec, qs ipc call bar toggle"
            "$mod, escape, exec, qs ipc call notifications dismissAll"
            "$mod, y, exec, qs ipc call notifications invoke"
            "$mod, x, exec, systemctl --user restart quickshell.service"
            "$mod, g, exec, qs ipc call wallpaper next"

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

            # Master Layout
            "$mod, n, layoutmsg, cyclenext"
            "$mod, return, layoutmsg, swapwithmaster master"
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
            ", XF86AudioLowerVolume,  exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
            ", XF86AudioRaiseVolume,  exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
            ", 248,                   exec, brightnessctl set --device=platform::kbd_backlight 5%-"
            ", XF86Calculator,        exec, brightnessctl set --device=platform::kbd_backlight 5%+"
            ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
            ", XF86MonBrightnessUp,   exec, brightnessctl set +5%"
          ];

          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];

          bindl = lib.optionals (hostname == "nona") [
            ", switch:on:Lid Switch, exec, hyprctl dispatch dpms off eDP-1"
            ", switch:off:Lid Switch, exec, hyprctl dispatch dpms on eDP-1"
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
              kb_variant = "";
            }
            {
              name = "cornemini-keyboard";
              kb_layout = "us";
              kb_variant = "";
            }
            {
              name = "zsa-technology-labs-voyager";
              kb_layout = "us";
              kb_variant = "";
            }
          ];

          gestures = {
            workspace_swipe_create_new = true;
            workspace_swipe_forever = true;
            workspace_swipe_touch = true;

            gesture = [
              "3, vertical, workspace"
              "3, right, dispatcher, layoutmsg, focus left"
              "3, left, dispatcher, layoutmsg, focus right"
              "3, pinchin, dispatcher, layoutmsg, colresize +conf"
              "3, pinchout, dispatcher, layoutmsg, colresize -conf"
            ];
          };

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
            "HYPRCURSOR_SIZE,${cursor_size_str}"
            "QT_QPA_PLATFORM,wayland;xcb"
            "QT_QPA_PLATFORMTHEME,kde"
            "SDL_VIDEODRIVER,wayland"
            "GDK_SCALE,1"
            "XCURSOR_SIZE,${cursor_size_str}"
            "XDG_CURRENT_DESKTOP,Hyprland"
            "XDG_SESSION_DESKTOP,Hyprland"
            "XDG_SESSION_TYPE,wayland"
            "HYPRSHOT_DIR,${import ../../../nix/_home.nix}/Pictures/Screenshots"
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

      xdg = {
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

      programs.wofi = {
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
              font-family: "NeoSpleen Nerd Font";
              font-size: 22px;
          }

          image {
              margin-left: 0.5em;
              margin-right: 0.5em;
          }
        '';
      };

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            after_sleep_cmd = "hyprctl dispatch dpms on";
            ignore_dbus_inhibit = false;
            lock_cmd = "qs ipc call lockscreen lock";
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "qs ipc call lockscreen lock";
            }
            {
              timeout = 360;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };
    };
}
