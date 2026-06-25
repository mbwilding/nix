{ inputs, ... }:

{
  flake.modules.nixos.hyprland =
    {
      pkgs,
      config,
      ...
    }:
    {
      imports = [
        inputs.self.modules.nixos.wayland-session
        inputs.self.modules.nixos.udiskie
      ];

      config = {
        host.waylandSession.sessionPackage = pkgs.hyprland;

        home-manager.sharedModules = [
          inputs.self.modules.homeManager.hyprland
          {
            _module.args.primaryMonitor = config.host.primaryMonitor;
          }
        ];

        programs = {
          hyprland = {
            enable = true;
            portalPackage = pkgs.xdg-desktop-portal-hyprland;
            xwayland.enable = true;
          };
        };

        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-hyprland
            pkgs.xdg-desktop-portal-gtk
          ];
          configPackages = [ pkgs.hyprland ];
          config = {
            hyprland = {
              default = [
                "hyprland"
                "gtk"
              ];
              "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
              "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
            };
            common = {
              default = [
                "hyprland"
                "gtk"
              ];
              "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
              "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
            };
          };
        };

        environment.systemPackages = [ pkgs.hyprpolkitagent ];
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
      lua = lib.generators.mkLuaInline;
      anim_speed = 1.8;
      gaps = 0.0;
      screenshotDir = "${import ../../../nix/_home.nix}/Pictures/Screenshots";
    in
    {
      imports = [
        inputs.self.modules.homeManager.noctalia
        inputs.self.modules.homeManager.udiskie
        inputs.self.modules.homeManager.desktop-theme
      ];

      home.packages = with pkgs; [
        hyprshot
        jq
        pulseaudio
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        package = pkgs.hyprland;
        portalPackage = pkgs.xdg-desktop-portal-hyprland;
        systemd = {
          enable = true;
          variables = [ "--all" ];
        };
        settings = {
          mod = {
            _var = "SUPER";
          };

          config = {
            ecosystem = {
              no_update_news = true;
              no_donation_nag = true;
            };

            general = {
              layout = "master";

              gaps_in = gaps;
              gaps_out = gaps * 2;
              border_size = 0;

              col = {
                active_border = "rgba(4eade5ee)";
                inactive_border = "rgba(787878ee)";
              };

              resize_on_border = true;

              allow_tearing = false;
            };

            master = {
              mfact = 0.5;
              smart_resizing = false;
              new_status = "slave";
              orientation = "left";
              center_master_fallback = "right";
              slave_count_for_center_master = 2;
            };

            dwindle = {
              preserve_split = true;
            };

            debug = {
              full_cm_proto = false;
            };

            decoration = {
              rounding = 0;

              active_opacity = 1.0;
              inactive_opacity = 1.0;

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
            };

            render = {
              send_content_type = true;
              direct_scanout = 1;
              cm_auto_hdr = 2;
              new_render_scheduling = false;
            };

            input = {
              kb_layout = "us";
              kb_variant = "dvorak";

              resolve_binds_by_sym = true;

              repeat_rate = 63;
              repeat_delay = 195;

              sensitivity = 0;
              force_no_accel = true;
              numlock_by_default = false;
              follow_mouse = 0;
              mouse_refocus = false;

              touchpad = {
                natural_scroll = true;
                scroll_factor = 1.0;
                disable_while_typing = false;
              };
            };

            xwayland = {
              force_zero_scaling = true;
            };

            scrolling = {
              fullscreen_on_one_column = true;
              follow_focus = true;
              direction = "right";
              focus_fit_method = 1;
              column_width = 0.333;
              explicit_column_widths = "0.25, 0.333, 0.5, 1.0";
            };

            cursor = {
              no_hardware_cursors = 2;
              no_break_fs_vrr = 2;
              hide_on_key_press = false;
              hide_on_touch = true;
              no_warps = false;
            };
          };

          # Extension point for host startup commands (exec-once equivalents)
          on = [ ];

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

          env = [
            {
              _args = [
                "CLUTTER_BACKEND"
                "wayland"
              ];
            }
            {
              _args = [
                "ELECTRON_OZONE_PLATFORM_HINT"
                "wayland"
              ];
            }
            {
              _args = [
                "GDK_BACKEND"
                "wayland,x11,*"
              ];
            }
            {
              _args = [
                "QT_AUTO_SCREEN_SCALE_FACTOR"
                "0"
              ];
            }
            {
              _args = [
                "QT_QPA_PLATFORM"
                "wayland;xcb"
              ];
            }
            {
              _args = [
                "QT_SCALE_FACTOR"
                "1"
              ];
            }
            {
              _args = [
                "SDL_VIDEODRIVER"
                "wayland"
              ];
            }
            {
              _args = [
                "GDK_DPI_SCALE"
                "1"
              ];
            }
            {
              _args = [
                "GDK_SCALE"
                "1"
              ];
            }
            {
              _args = [
                "XCURSOR_SIZE"
                "24"
              ];
            }
            {
              _args = [
                "XDG_CURRENT_DESKTOP"
                "Hyprland"
              ];
            }
            {
              _args = [
                "XDG_SESSION_DESKTOP"
                "Hyprland"
              ];
            }
            {
              _args = [
                "XDG_SESSION_TYPE"
                "wayland"
              ];
            }
            {
              _args = [
                "HYPRSHOT_DIR"
                screenshotDir
              ];
            }
          ];

          animation = [
            {
              leaf = "workspaces";
              enabled = false;
            }
            {
              leaf = "windows";
              enabled = true;
              speed = anim_speed;
              bezier = "default";
            }
            {
              leaf = "layers";
              enabled = true;
              speed = anim_speed;
              bezier = "default";
            }
            {
              leaf = "fade";
              enabled = true;
              speed = anim_speed;
              bezier = "default";
            }
            {
              leaf = "border";
              enabled = true;
              speed = anim_speed;
              bezier = "default";
            }
            {
              leaf = "borderangle";
              enabled = true;
              speed = anim_speed;
              bezier = "default";
            }
            {
              leaf = "zoomFactor";
              enabled = true;
              speed = anim_speed;
              bezier = "default";
            }
            {
              leaf = "monitorAdded";
              enabled = true;
              speed = anim_speed;
              bezier = "default";
            }
          ];

          bind = [
            {
              _args = [
                (lua "mod .. \" + b\"")
                (lua ''hl.dsp.exec_cmd("google-chrome")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + c\"")
                (lua ''hl.dsp.exec_cmd("ghostty -e btop +new-window")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + d\"")
                (lua ''hl.dsp.exec_cmd("vesktop")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + e\"")
                (lua ''hl.dsp.exec_cmd("ghostty -e yazi +new-window")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + m\"")
                (lua ''hl.dsp.exec_cmd("teams-for-linux")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + p\"")
                (lua ''hl.dsp.exec_cmd("1password")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + r\"")
                (lua ''hl.dsp.exec_cmd("noctalia msg panel-toggle launcher")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + s\"")
                (lua ''hl.dsp.exec_cmd("spotify")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + t\"")
                (lua ''hl.dsp.exec_cmd("ghostty +new-window")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + z\"")
                (lua ''hl.dsp.exec_cmd("noctalia msg session lock")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + g\"")
                (lua ''hl.dsp.exec_cmd("systemd-run --user --scope steam -beta publicbeta")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + comma\"")
                (lua ''hl.dsp.exec_cmd("noctalia msg settings-toggle")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + minus\"")
                (lua ''hl.dsp.exec_cmd("ecc toggle")'')
              ];
            }

            {
              _args = [
                (lua "mod .. \" + f\"")
                (lua "hl.dsp.window.float({ action = \"toggle\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + o\"")
                (lua "hl.dsp.window.fullscreen()")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + q\"")
                (lua "hl.dsp.window.close()")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + grave\"")
                (lua "hl.dsp.exit()")
              ];
            }

            {
              _args = [
                (lua "mod .. \" + semicolon\"")
                (lua ''hl.dsp.exec_cmd("hyprshot -m window -m active --clipboard-only")'')
              ];
            }
            {
              _args = [
                (lua "mod .. \" + apostrophe\"")
                (lua ''hl.dsp.exec_cmd("hyprshot -m region")'')
              ];
            }

            # Switch window focus
            {
              _args = [
                (lua "mod .. \" + h\"")
                (lua "hl.dsp.focus({ direction = \"left\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + l\"")
                (lua "hl.dsp.focus({ direction = \"right\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + k\"")
                (lua "hl.dsp.focus({ direction = \"up\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + j\"")
                (lua "hl.dsp.focus({ direction = \"down\" })")
              ];
            }

            # Swap window positions
            {
              _args = [
                (lua "mod .. \" + SHIFT + h\"")
                (lua "hl.dsp.window.swap({ direction = \"left\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + SHIFT + l\"")
                (lua "hl.dsp.window.swap({ direction = \"right\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + SHIFT + k\"")
                (lua "hl.dsp.window.swap({ direction = \"up\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + SHIFT + j\"")
                (lua "hl.dsp.window.swap({ direction = \"down\" })")
              ];
            }

            {
              _args = [
                "Print"
                (lua ''hl.dsp.exec_cmd("hyprshot -m window -m active")'')
              ];
            }

            # Scroll through existing workspaces with mod + scroll
            {
              _args = [
                (lua "mod .. \" + mouse_down\"")
                (lua "hl.dsp.focus({ workspace = \"e+1\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + mouse_up\"")
                (lua "hl.dsp.focus({ workspace = \"e-1\" })")
              ];
            }

            # Media keys
            {
              _args = [
                "XF86AudioMute"
                (lua ''hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle")'')
                { locked = true; }
              ];
            }
            {
              _args = [
                "XF86AudioMicMute"
                (lua ''hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle")'')
                { locked = true; }
              ];
            }

            # Master layout
            {
              _args = [
                (lua "mod .. \" + n\"")
                (lua "hl.dsp.layout(\"cyclenext\")")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + return\"")
                (lua "hl.dsp.layout(\"swapwithmaster master\")")
              ];
            }

            # Workspace switching (Dvorak home row: h=1 t=2 n=3 s=4 -=5)
            {
              _args = [
                (lua "mod .. \" + CTRL + h\"")
                (lua "hl.dsp.focus({ workspace = \"1\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + CTRL + t\"")
                (lua "hl.dsp.focus({ workspace = \"2\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + CTRL + n\"")
                (lua "hl.dsp.focus({ workspace = \"3\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + CTRL + s\"")
                (lua "hl.dsp.focus({ workspace = \"4\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + CTRL + minus\"")
                (lua "hl.dsp.focus({ workspace = \"5\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + CTRL + SHIFT + h\"")
                (lua "hl.dsp.window.move({ workspace = \"1\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + CTRL + SHIFT + t\"")
                (lua "hl.dsp.window.move({ workspace = \"2\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + CTRL + SHIFT + n\"")
                (lua "hl.dsp.window.move({ workspace = \"3\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + CTRL + SHIFT + s\"")
                (lua "hl.dsp.window.move({ workspace = \"4\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + CTRL + SHIFT + minus\"")
                (lua "hl.dsp.window.move({ workspace = \"5\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + 6\"")
                (lua "hl.dsp.focus({ workspace = \"name:social\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + 7\"")
                (lua "hl.dsp.focus({ workspace = \"name:spare\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + SHIFT + 6\"")
                (lua "hl.dsp.window.move({ workspace = \"name:social\" })")
              ];
            }
            {
              _args = [
                (lua "mod .. \" + SHIFT + 7\"")
                (lua "hl.dsp.window.move({ workspace = \"name:spare\" })")
              ];
            }

            # Repeating volume / brightness binds
            {
              _args = [
                "XF86AudioLowerVolume"
                (lua ''hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%")'')
                { repeating = true; }
              ];
            }
            {
              _args = [
                "XF86AudioRaiseVolume"
                (lua ''hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%")'')
                { repeating = true; }
              ];
            }
            {
              _args = [
                "code:248"
                (lua ''hl.dsp.exec_cmd("brightnessctl set --device=platform::kbd_backlight 5%-")'')
                { repeating = true; }
              ];
            }
            {
              _args = [
                "XF86Calculator"
                (lua ''hl.dsp.exec_cmd("brightnessctl set --device=platform::kbd_backlight 5%+")'')
                { repeating = true; }
              ];
            }
            {
              _args = [
                "XF86MonBrightnessDown"
                (lua ''hl.dsp.exec_cmd("brightnessctl set 5%-")'')
                { repeating = true; }
              ];
            }
            {
              _args = [
                "XF86MonBrightnessUp"
                (lua ''hl.dsp.exec_cmd("brightnessctl set +5%")'')
                { repeating = true; }
              ];
            }

            # Mouse move/resize
            {
              _args = [
                (lua "mod .. \" + mouse:272\"")
                (lua "hl.dsp.window.drag()")
                { mouse = true; }
              ];
            }
            {
              _args = [
                (lua "mod .. \" + mouse:273\"")
                (lua "hl.dsp.window.resize()")
                { mouse = true; }
              ];
            }

            # Lid switch
            {
              _args = [
                "switch:on:Lid Switch"
                (lua ''hl.dsp.exec_cmd("noctalia msg session lock && hyprctl dispatch 'hl.dsp.dpms(\"off\")' && [ $(cat /sys/class/power_supply/AC/online) -eq 0 ] && systemctl suspend")'')
                { locked = true; }
              ];
            }
            {
              _args = [
                "switch:off:Lid Switch"
                (lua ''hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.dpms(\"on\")'")'')
                { locked = true; }
              ];
            }
          ];

          gesture = [
            {
              fingers = 3;
              direction = "vertical";
              action = "workspace";
            }
            {
              fingers = 3;
              direction = "pinchin";
              action = lua ''function() hl.dispatch(hl.dsp.layout("colresize +conf")) end'';
            }
            {
              fingers = 3;
              direction = "pinchout";
              action = lua ''function() hl.dispatch(hl.dsp.layout("colresize -conf")) end'';
            }
          ];

          monitor = [ ];

          workspace_rule = [ ];

          window_rule = [ ];
        };

        extraConfig = ''
          hl.on("hyprland.start", function()
            hl.exec_cmd("noctalia")
            hl.exec_cmd("systemctl --user start hyprpolkitagent")
          end)
        '';
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "image/png" = "imv.desktop";
          "image/jpeg" = "imv.desktop";
          "image/gif" = "imv.desktop";
          "image/bmp" = "imv.desktop";
          "image/svg+xml" = "imv.desktop";
          "image/tiff" = "imv.desktop";
          "image/webp" = "imv.desktop";
          "image/x-icon" = "imv.desktop";
        };
      };

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })' && brightnessctl -r";
            ignore_dbus_inhibit = false;
            lock_cmd = "noctalia msg session lock";
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "noctalia msg session lock";
            }
            {
              timeout = 330;
              on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
              on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })' && brightnessctl -r";
            }
            # {
            #   timeout = 1800;
            #   on-timeout = "systemctl suspend";
            # }
          ];
        };
      };
    };
}
