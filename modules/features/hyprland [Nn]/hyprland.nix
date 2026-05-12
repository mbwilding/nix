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
      anim_speed = 2.0;

      gaps = 0.0; # 10.0
      cursor_size = 24;
      cursor_size_str = builtins.toString cursor_size;

      anim_speed_str = builtins.toString anim_speed;

      monitors = if primaryMonitor != "" then [ primaryMonitor ] else [ ];
    in
    {
      home = {
        packages = with pkgs; [
          # hyprnotify
          # wayle
          hyprshot
          jq
          kdePackages.breeze
          kdePackages.plasma-integration
          noctalia-qs
          noctalia-shell
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
            "noctalia-shell"
            "systemctl --user start hyprpolkitagent"
            # "hyprnotify"
            # "hyprpanel"
            # "hyprpaper"
            # "nm-applet"
            # "wayle panel start"
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
            "$mod, r, exec, noctalia-shell ipc call launcher toggle"
            "$mod, s, exec, spotify"
            "$mod, t, exec, ghostty +new-window"
            "$mod, z, exec, noctalia-shell ipc call lockScreen lock"
            "$mod, comma, exec, noctalia-shell ipc call settings toggle"
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
            ", switch:on:Lid Switch, exec, noctalia-shell ipc call lockScreen lock && hyprctl dispatch dpms off ${primaryMonitor} && [ $(cat /sys/class/power_supply/AC/online) -eq 0 ] && systemctl suspend"
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
            # Cursor size — override in host _hyprland.nix if needed
            "HYPRCURSOR_SIZE,${cursor_size_str}"
            "XCURSOR_SIZE,${cursor_size_str}"
          ];

          workspace = [ ];

          windowrule = [
            {
              name = "UnrealEngine";
              workspace = "name:main";
              no_anim = "on";
              no_initial_focus = "on";
              "match:class" = "^(UnrealEditor)$";
              "match:title" = "^\w*$";
            }
          ];

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

      # home.file.".config/wayle/config.toml".text = ''
      #   # https://wayle.app/config
      #
      #   [bar]
      #   location = "top"
      #   scale = 1.0
      #
      #   [[bar.layout]]
      #   monitor = "*"
      #   left = ["dashboard", "idle-inhibit"]
      #   center = ["clock"]
      #   right = ["volume", "network", "bluetooth", "battery"]
      #
      #   [modules.clock]
      #   format = "%H:%M"
      # '';

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

      home.file.".config/noctalia/colors.json".text = builtins.toJSON {
        mPrimary = "#39bae6";
        mSecondary = "#aad94c";
        mTertiary = "#e6b450";
        mError = "#d95757";
        mHover = "#39bae6";
        mOnError = "#0b0e14";
        mOnHover = "#0b0e14";
        mOnPrimary = "#0b0e14";
        mOnSecondary = "#0b0e14";
        mOnSurface = "#d1d1c7";
        mOnSurfaceVariant = "#8e959e";
        mOnTertiary = "#0b0e14";
        mOutline = "#565b66";
        mShadow = "#000000";
        mSurface = "#0b0e14";
        mSurfaceVariant = "#1e222a";
      };

      home.file.".config/noctalia/plugins.json".text = builtins.toJSON {
        sources = [
          {
            enabled = true;
            name = "Noctalia Plugins";
            url = "https://github.com/noctalia-dev/noctalia-plugins";
          }
        ];
        states = { };
        version = 2;
      };

      home.file.".config/noctalia/settings.json".text = builtins.toJSON {
        appLauncher = {
          autoPasteClipboard = false;
          clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
          clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
          clipboardWrapText = true;
          customLaunchPrefix = "";
          customLaunchPrefixEnabled = false;
          density = "default";
          enableClipPreview = true;
          enableClipboardChips = true;
          enableClipboardHistory = false;
          enableClipboardSmartIcons = true;
          enableSessionSearch = true;
          enableSettingsSearch = true;
          enableWindowsSearch = true;
          iconMode = "tabler";
          ignoreMouseInput = false;
          overviewLayer = true;
          pinnedApps = [ ];
          position = "center";
          screenshotAnnotationTool = "";
          showCategories = true;
          showIconBackground = false;
          sortByMostUsed = true;
          terminalCommand = "ghostty -e";
          viewMode = "grid";
        };
        audio = {
          mprisBlacklist = [ ];
          preferredPlayer = "";
          spectrumFrameRate = 30;
          spectrumMirrored = true;
          visualizerType = "linear";
          volumeFeedback = false;
          volumeFeedbackSoundFile = "";
          volumeOverdrive = false;
          volumeStep = 5;
        };
        bar = {
          autoHideDelay = 500;
          autoShowDelay = 150;
          backgroundOpacity = 0.93;
          barType = "simple";
          capsuleColorKey = "none";
          capsuleOpacity = 1;
          contentPadding = 2;
          density = "spacious";
          displayMode = "auto_hide";
          enableExclusionZoneInset = true;
          fontScale = 1;
          frameRadius = 12;
          frameThickness = 8;
          hideOnOverview = false;
          marginHorizontal = 4;
          marginVertical = 4;
          middleClickAction = "none";
          middleClickCommand = "";
          middleClickFollowMouse = false;
          monitors = [ ];
          mouseWheelAction = "none";
          mouseWheelWrap = true;
          outerCorners = true;
          position = "bottom";
          reverseScroll = false;
          rightClickAction = "controlCenter";
          rightClickCommand = "";
          rightClickFollowMouse = true;
          screenOverrides = [ ];
          showCapsule = false;
          showOnWorkspaceSwitch = false;
          showOutline = false;
          useSeparateOpacity = false;
          widgetSpacing = 6;
          widgets = {
            center = [
              {
                clockColor = "none";
                customFont = "";
                formatHorizontal = "HH:mm ddd, MMM dd";
                formatVertical = "HH mm - dd MM";
                id = "Clock";
                tooltipFormat = "HH:mm ddd, MMM dd";
                useCustomFont = false;
              }
            ];
            left = [
              {
                colorizeSystemIcon = "none";
                colorizeSystemText = "none";
                customIconPath = "";
                enableColorization = false;
                icon = "rocket";
                iconColor = "none";
                id = "Launcher";
                useDistroLogo = false;
              }
              {
                characterCount = 2;
                colorizeIcons = false;
                emptyColor = "secondary";
                enableScrollWheel = true;
                focusedColor = "primary";
                followFocusedScreen = false;
                fontWeight = "medium";
                groupedBorderOpacity = 1;
                hideUnoccupied = true;
                iconScale = 0.8;
                id = "Workspace";
                labelMode = "name";
                occupiedColor = "secondary";
                pillSize = 0.6;
                showApplications = true;
                showApplicationsHover = false;
                showBadge = true;
                showLabelsOnlyWhenOccupied = true;
                unfocusedIconsOpacity = 1;
              }
              {
                compactMode = false;
                hideMode = "hidden";
                hideWhenIdle = false;
                id = "MediaMini";
                maxWidth = 145;
                panelShowAlbumArt = true;
                scrollingMode = "hover";
                showAlbumArt = true;
                showArtistFirst = true;
                showProgressRing = true;
                showVisualizer = false;
                textColor = "none";
                useFixedWidth = false;
                visualizerType = "linear";
              }
            ];
            right = [
              {
                blacklist = [ ];
                chevronColor = "none";
                colorizeIcons = false;
                drawerEnabled = false;
                hidePassive = false;
                id = "Tray";
                pinned = [ ];
              }
              {
                compactMode = true;
                diskPath = "/";
                iconColor = "none";
                id = "SystemMonitor";
                showCpuCores = false;
                showCpuFreq = false;
                showCpuTemp = true;
                showCpuUsage = true;
                showDiskAvailable = false;
                showDiskUsage = false;
                showDiskUsageAsPercent = false;
                showGpuTemp = false;
                showLoadAverage = false;
                showMemoryAsPercent = false;
                showMemoryUsage = true;
                showNetworkStats = false;
                showSwapUsage = false;
                textColor = "none";
                useMonospaceFont = true;
                usePadding = false;
              }
              {
                hideWhenZero = false;
                hideWhenZeroUnread = false;
                iconColor = "none";
                id = "NotificationHistory";
                showUnreadBadge = true;
                unreadBadgeColor = "primary";
              }
              {
                deviceNativePath = "__default__";
                displayMode = "graphic-clean";
                hideIfIdle = false;
                hideIfNotDetected = true;
                id = "Battery";
                showNoctaliaPerformance = false;
                showPowerProfiles = false;
              }
              {
                displayMode = "onhover";
                iconColor = "none";
                id = "Volume";
                middleClickCommand = "pwvucontrol || pavucontrol";
                textColor = "none";
              }
              {
                applyToAllMonitors = false;
                displayMode = "onhover";
                iconColor = "none";
                id = "Brightness";
                textColor = "none";
              }
              {
                colorizeDistroLogo = false;
                colorizeSystemIcon = "none";
                colorizeSystemText = "none";
                customIconPath = "";
                enableColorization = false;
                icon = "noctalia";
                id = "ControlCenter";
                useDistroLogo = false;
              }
            ];
          };
        };
        brightness = {
          backlightDeviceMappings = [ ];
          brightnessStep = 5;
          enableDdcSupport = false;
          enforceMinimum = true;
        };
        calendar = {
          cards = [
            {
              enabled = true;
              id = "calendar-header-card";
            }
            {
              enabled = true;
              id = "calendar-month-card";
            }
            {
              enabled = true;
              id = "weather-card";
            }
          ];
        };
        colorSchemes = {
          darkMode = true;
          generationMethod = "tonal-spot";
          manualSunrise = "06:30";
          manualSunset = "18:30";
          monitorForColors = "";
          predefinedScheme = "Ayu";
          schedulingMode = "off";
          syncGsettings = true;
          useWallpaperColors = false;
        };
        controlCenter = {
          cards = [
            {
              enabled = true;
              id = "profile-card";
            }
            {
              enabled = true;
              id = "shortcuts-card";
            }
            {
              enabled = true;
              id = "audio-card";
            }
            {
              enabled = false;
              id = "brightness-card";
            }
            {
              enabled = true;
              id = "weather-card";
            }
            {
              enabled = true;
              id = "media-sysmon-card";
            }
          ];
          diskPath = "/";
          position = "close_to_bar_button";
          shortcuts = {
            left = [
              {
                id = "Network";
              }
              {
                id = "Bluetooth";
              }
              {
                id = "WallpaperSelector";
              }
              {
                id = "NoctaliaPerformance";
              }
            ];
            right = [
              {
                id = "Notifications";
              }
              {
                id = "PowerProfile";
              }
              {
                id = "KeepAwake";
              }
              {
                id = "NightLight";
              }
            ];
          };
        };
        desktopWidgets = {
          enabled = false;
          gridSnap = false;
          gridSnapScale = false;
          monitorWidgets = [ ];
          overviewEnabled = true;
        };
        dock = {
          animationSpeed = 1;
          backgroundOpacity = 1;
          colorizeIcons = false;
          deadOpacity = 0.6;
          displayMode = "auto_hide";
          dockType = "floating";
          enabled = false;
          floatingRatio = 1;
          groupApps = false;
          groupClickAction = "cycle";
          groupContextMenuMode = "extended";
          groupIndicatorStyle = "dots";
          inactiveIndicators = false;
          indicatorColor = "primary";
          indicatorOpacity = 0.6;
          indicatorThickness = 3;
          launcherIcon = "";
          launcherIconColor = "none";
          launcherPosition = "end";
          launcherUseDistroLogo = false;
          monitors = [ ];
          onlySameOutput = true;
          pinnedApps = [ ];
          pinnedStatic = false;
          position = "top";
          showDockIndicator = false;
          showLauncherIcon = false;
          sitOnFrame = false;
          size = 1;
        };
        general = {
          allowPanelsOnScreenWithoutBar = true;
          allowPasswordWithFprintd = false;
          animationDisabled = false;
          animationSpeed = 1;
          autoStartAuth = false;
          avatarImage = "/home/anon/.face";
          boxRadiusRatio = 1;
          clockFormat = "hh\\nmm";
          clockStyle = "custom";
          compactLockScreen = false;
          dimmerOpacity = 0.2;
          enableBlurBehind = true;
          enableLockScreenCountdown = false;
          enableLockScreenMediaControls = false;
          enableShadows = true;
          forceBlackScreenCorners = false;
          iRadiusRatio = 1;
          keybinds = {
            keyDown = [
              "Down"
            ];
            keyEnter = [
              "Return"
              "Enter"
            ];
            keyEscape = [
              "Esc"
            ];
            keyLeft = [
              "Left"
            ];
            keyRemove = [
              "Del"
            ];
            keyRight = [
              "Right"
            ];
            keyUp = [
              "Up"
            ];
          };
          language = "";
          lockOnSuspend = true;
          lockScreenAnimations = false;
          lockScreenBlur = 0;
          lockScreenCountdownDuration = 10000;
          lockScreenMonitors = monitors;
          lockScreenTint = 0;
          passwordChars = false;
          radiusRatio = 1;
          reverseScroll = false;
          scaleRatio = 1;
          screenRadiusRatio = 1;
          shadowDirection = "bottom_right";
          shadowOffsetX = 2;
          shadowOffsetY = 3;
          showChangelogOnStartup = true;
          showHibernateOnLockScreen = false;
          showScreenCorners = false;
          showSessionButtonsOnLockScreen = true;
          smoothScrollEnabled = true;
          telemetryEnabled = false;
        };
        hooks = {
          colorGeneration = "";
          darkModeChange = "";
          enabled = false;
          performanceModeDisabled = "";
          performanceModeEnabled = "";
          screenLock = "";
          screenUnlock = "";
          session = "";
          startup = "";
          wallpaperChange = "";
        };
        idle = {
          customCommands = "[]";
          enabled = true;
          fadeDuration = 5;
          lockCommand = "";
          lockTimeout = 660;
          resumeLockCommand = "";
          resumeScreenOffCommand = "";
          resumeSuspendCommand = "";
          screenOffCommand = "";
          screenOffTimeout = 600;
          suspendCommand = "";
          suspendTimeout = 0;
        };
        location = {
          analogClockInCalendar = false;
          autoLocate = false;
          firstDayOfWeek = 1;
          hideWeatherCityName = false;
          hideWeatherTimezone = false;
          name = "Perth, Australia";
          showCalendarEvents = true;
          showCalendarWeather = true;
          showWeekNumberInCalendar = false;
          use12hourFormat = false;
          useFahrenheit = false;
          weatherEnabled = true;
          weatherShowEffects = true;
          weatherTaliaMascotAlways = false;
        };
        network = {
          bluetoothAutoConnect = true;
          bluetoothDetailsViewMode = "grid";
          bluetoothHideUnnamedDevices = false;
          bluetoothRssiPollIntervalMs = 60000;
          bluetoothRssiPollingEnabled = false;
          disableDiscoverability = false;
          networkPanelView = "wifi";
          wifiDetailsViewMode = "grid";
        };
        nightLight = {
          autoSchedule = true;
          dayTemp = "6500";
          enabled = false;
          forced = false;
          manualSunrise = "06:30";
          manualSunset = "18:30";
          nightTemp = "4000";
        };
        noctaliaPerformance = {
          disableDesktopWidgets = true;
          disableWallpaper = true;
        };
        notifications = {
          backgroundOpacity = 1;
          clearDismissed = true;
          criticalUrgencyDuration = 15;
          density = "default";
          enableBatteryToast = true;
          enableKeyboardLayoutToast = true;
          enableMarkdown = false;
          enableMediaToast = false;
          enabled = true;
          location = "top_right";
          lowUrgencyDuration = 3;
          monitors = monitors;
          normalUrgencyDuration = 8;
          overlayLayer = true;
          respectExpireTimeout = false;
          saveToHistory = {
            critical = true;
            low = true;
            normal = true;
          };
          sounds = {
            criticalSoundFile = "";
            enabled = false;
            excludedApps = "discord,firefox,chrome,chromium,edge";
            lowSoundFile = "";
            normalSoundFile = "";
            separateSounds = false;
            volume = 0.5;
          };
        };
        osd = {
          autoHideMs = 2000;
          backgroundOpacity = 1;
          enabled = true;
          enabledTypes = [
            0
            1
            2
          ];
          location = "top_right";
          monitors = monitors;
          overlayLayer = true;
        };
        plugins = {
          autoUpdate = true;
          notifyUpdates = true;
        };
        sessionMenu = {
          countdownDuration = 10000;
          enableCountdown = true;
          largeButtonsLayout = "single-row";
          largeButtonsStyle = true;
          position = "center";
          powerOptions = [
            {
              action = "lock";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "1";
            }
            {
              action = "suspend";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "2";
            }
            {
              action = "hibernate";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "3";
            }
            {
              action = "reboot";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "4";
            }
            {
              action = "logout";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "5";
            }
            {
              action = "shutdown";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "6";
            }
            {
              action = "rebootToUefi";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "7";
            }
            {
              action = "userspaceReboot";
              command = "";
              countdownEnabled = true;
              enabled = false;
              keybind = "";
            }
          ];
          showHeader = true;
          showKeybinds = true;
        };
        settingsVersion = 59;
        systemMonitor = {
          batteryCriticalThreshold = 5;
          batteryWarningThreshold = 20;
          cpuCriticalThreshold = 90;
          cpuWarningThreshold = 80;
          criticalColor = "";
          diskAvailCriticalThreshold = 10;
          diskAvailWarningThreshold = 20;
          diskCriticalThreshold = 90;
          diskWarningThreshold = 80;
          enableDgpuMonitoring = true;
          externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
          gpuCriticalThreshold = 90;
          gpuWarningThreshold = 80;
          memCriticalThreshold = 90;
          memWarningThreshold = 80;
          swapCriticalThreshold = 90;
          swapWarningThreshold = 80;
          tempCriticalThreshold = 90;
          tempWarningThreshold = 80;
          useCustomColors = false;
          warningColor = "";
        };
        templates = {
          activeTemplates = [ ];
          enableUserTheming = false;
        };
        ui = {
          boxBorderEnabled = false;
          fontDefault = "Segoe UI";
          fontDefaultScale = 1;
          fontFixed = "NeoSpleen Nerd Font";
          fontFixedScale = 1;
          panelBackgroundOpacity = 0.93;
          panelsAttachedToBar = true;
          scrollbarAlwaysVisible = true;
          settingsPanelMode = "attached";
          settingsPanelSideBarCardStyle = false;
          tooltipsEnabled = true;
          translucentWidgets = false;
        };
        wallpaper = {
          automationEnabled = true;
          directory = "/home/anon/nix/wallpapers";
          enableMultiMonitorDirectories = false;
          enabled = true;
          favorites = [ ];
          fillColor = "#000000";
          fillMode = "crop";
          hideWallpaperFilenames = false;
          linkLightAndDarkWallpapers = true;
          monitorDirectories = [ ];
          overviewBlur = 0.4;
          overviewEnabled = false;
          overviewTint = 0.6;
          panelPosition = "follow_bar";
          randomIntervalSec = 300;
          setWallpaperOnAllMonitors = true;
          showHiddenFiles = false;
          skipStartupTransition = false;
          solidColor = "#1a1a2e";
          sortOrder = "name";
          transitionDuration = 1500;
          transitionEdgeSmoothness = 0.05;
          transitionType = [
            "fade"
            "disc"
            "stripes"
            "wipe"
            "pixelate"
            "honeycomb"
          ];
          useOriginalImages = true;
          useSolidColor = false;
          useWallhaven = false;
          viewMode = "recursive";
          wallhavenApiKey = "";
          wallhavenCategories = "111";
          wallhavenOrder = "desc";
          wallhavenPurity = "100";
          wallhavenQuery = "";
          wallhavenRatios = "";
          wallhavenResolutionHeight = "";
          wallhavenResolutionMode = "atleast";
          wallhavenResolutionWidth = "";
          wallhavenSorting = "relevance";
          wallpaperChangeMode = "random";
        };
      };
    };
}
