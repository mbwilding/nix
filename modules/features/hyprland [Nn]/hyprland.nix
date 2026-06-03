{ inputs, ... }:

{
  flake.modules.nixos.hyprland =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.host.primaryMonitor = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Primary monitor output name for this host (e.g. HDMI-A-1, eDP-1).";
      };

      config = {
        home-manager.sharedModules = [
          inputs.self.modules.homeManager.hyprland
          inputs.self.modules.homeManager.theme
          { _module.args.primaryMonitor = config.host.primaryMonitor; }
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
    };

  flake.modules.homeManager.hyprland =
    {
      lib,
      pkgs,
      osConfig ? null,
      primaryMonitor ? (if osConfig != null then osConfig.host.primaryMonitor else ""),
      ...
    }:

    let
      gaps = 0.0; # 10.0
      anim_speed = 2.0;
      anim_speed_str = builtins.toString anim_speed;
      monitors = if primaryMonitor != "" then [ primaryMonitor ] else [ ];
    in
    {
      imports = [ inputs.noctalia.homeModules.default ];
      home = {
        packages = with pkgs; [
          hyprshot
          jq
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
        configType = "hyprlang"; # TODO: lua
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
            layout = "scrolling"; # master

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
            # pseudotile = true; # TODO: Find replacement in 0.55
            preserve_split = true;
          };

          debug = {
            full_cm_proto = false;
          };

          decoration = {
            rounding = 0; # 10

            active_opacity = 1.0;
            inactive_opacity = 1.0; # 0.96

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
            # vfr = true; # TODO: Find replacement in 0.55
          };

          render = {
            send_content_type = true;
            direct_scanout = 1;
            # cm_fs_passthrough = 2; # TODO: Find replacement in 0.55
            cm_auto_hdr = 2;
            new_render_scheduling = false;
          };

          exec-once = [
            "noctalia"
            "systemctl --user start hyprpolkitagent"
          ];

          "$mod" = "SUPER";
          bind = [
            "$mod, b, exec, firefox"
            "$mod, c, exec, ghostty -e btop +new-window"
            "$mod, d, exec, discord"
            "$mod, e, exec, dolphin"
            "$mod, m, exec, teams-for-linux"
            # "$mod, n, exec, neovide"
            "$mod, p, exec, 1password"
            "$mod, r, exec, noctalia msg panel-toggle launcher"
            "$mod, s, exec, spotify"
            "$mod, t, exec, ghostty +new-window"
            "$mod, z, exec, noctalia msg session lock"
            "$mod, comma, exec, noctalia msg settings-toggle"
            "$mod, minus, exec, ecc toggle"

            "$mod, f, togglefloating,"
            "$mod, o, fullscreen,"
            "$mod, q, killactive,"
            "$mod, grave, exit,"

            "$mod, semicolon, exec, hyprshot -m window -m active --clipboard-only"
            "$mod, apostrophe, exec, hyprshot -m region"

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
          ++ [
            "$mod CTRL, h, workspace, 1"
            "$mod CTRL, t, workspace, 2"
            "$mod CTRL, n, workspace, 3"
            "$mod CTRL, s, workspace, 4"
            "$mod CTRL, minus, workspace, 5"
            "$mod CTRL SHIFT, h, movetoworkspace, 1"
            "$mod CTRL SHIFT, t, movetoworkspace, 2"
            "$mod CTRL SHIFT, n, movetoworkspace, 3"
            "$mod CTRL SHIFT, s, movetoworkspace, 4"
            "$mod CTRL SHIFT, minus, movetoworkspace, 5"
            "$mod, 6, workspace, name:social"
            "$mod, 7, workspace, name:spare"
            "$mod SHIFT, 6, movetoworkspace, name:social"
            "$mod SHIFT, 7, movetoworkspace, name:spare"
          ];

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

          bindl = [
            ", switch:on:Lid Switch, exec, noctalia msg session lock && hyprctl dispatch dpms off ${primaryMonitor} && [ $(cat /sys/class/power_supply/AC/online) -eq 0 ] && systemctl suspend"
            ", switch:off:Lid Switch, exec, hyprctl dispatch dpms on ${primaryMonitor}"
          ];

          animations = {
            enabled = true;
            animation = [
              "workspaces, 0, 0.0, default"
              "windows, 1, ${anim_speed_str}, default"
              "layers, 1, ${anim_speed_str}, default"
              "fade, 1, ${anim_speed_str}, default"
              "border, 1, ${anim_speed_str}, default"
              "borderangle, 1, ${anim_speed_str}, default"
              "zoomFactor, 1, ${anim_speed_str}, default"
              "monitorAdded, 1, ${anim_speed_str}, default"
            ];
          };

          xwayland = {
            force_zero_scaling = true;
          };

          monitorv2 = [ ];

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
            "QT_QPA_PLATFORM,wayland;xcb"
            "QT_QPA_PLATFORMTHEME,kde"
            "SDL_VIDEODRIVER,wayland"
            "GDK_SCALE,1"
            "XDG_CURRENT_DESKTOP,Hyprland"
            "XDG_SESSION_DESKTOP,Hyprland"
            "XDG_SESSION_TYPE,wayland"
            "HYPRSHOT_DIR,${import ../../nix/_home.nix}/Pictures/Screenshots"
          ];

          workspace = [ ];

          windowrule = [ ];

          scrolling = {
            fullscreen_on_one_column = true;
            follow_focus = true;
            direction = "right";
          };

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

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            after_sleep_cmd = "hyprctl dispatch dpms on";
            ignore_dbus_inhibit = false;
            lock_cmd = "noctalia msg session lock";
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "noctalia msg session lock";
            }
            {
              timeout = 360;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };

      programs.noctalia = {
        enable = true;
        settings = {
          bar.default = {
            auto_hide = true;
            layer = "overlay";
            position = "bottom";
            scale = 1.2;
            thickness = 38;

            start = [
              "session"
              "control-center"
              "launcher"
              "wallpaper"
              "clipboard"
              "cpu"
              "ram"
              "temp"
              "network_rx"
              "network_tx"
            ];
            center = [
              "workspaces"
              "media"
            ];
            end = [
              "tray"
              "network"
              "volume"
              "bluetooth"
              "notifications"
              "brightness"
              "battery"
              "clock"
            ];
          };

          lockscreen.blurred_desktop = true;
          dock.auto_hide = true;
          location.address = "Perth, Australia";

          shell = {
            font_family = "NeoSpleen Nerd Font";
            lang = "en";
            settings_show_advanced = true;
            animation.speed = 2.0;
            panel = {
              launcher_categories = false;
              launcher_placement = "centered";
              open_near_click_session = true;
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
            directory = "/home/anon/nix/wallpapers";
            directory_dark = "";
            default.path = "/home/anon/nix/wallpapers/retrowave/futuristic-city-5120x2880-15887.jpg";
            automation = {
              enabled = true;
              interval_minutes = 3;
            };
          };

          widget = {
            workspaces = {
              empty_color = "on_secondary";
              hide_when_empty = true;
              labels_only_when_occupied = true;
            };
          };
        };
      };

      home.file.".config/hypr/.luarc.json".text = builtins.toJSON {
        workspace = {
          library = [
            "${pkgs.hyprland}/share/hypr/stubs"
          ];
        };
        diganostics = {
          globals = [
            "hl"
          ];
        };
      };
    };
}
