{ ... }:

let
  font = "NeoSpleen Nerd Font";
in
{
  programs = {
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
