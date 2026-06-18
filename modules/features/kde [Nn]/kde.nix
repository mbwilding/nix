{ inputs, ... }:

{
  flake.modules.nixos.kde =
    { pkgs, ... }:
    {
      home-manager.sharedModules = [ inputs.self.modules.homeManager.kde ];

      hardware.graphics.extraPackages = with pkgs; [
        vulkan-hdr-layer-kwin6
      ];

      services = {
        xserver.enable = false;

        desktopManager.plasma6.enable = true;

        displayManager = {
          plasma-login-manager = {
            enable = true;
            settings = {
              Users = {
                ReuseSession = false;
              };
              Greeter = {
                WallpaperPluginId = "org.kde.color";
                Color = "0,0,0";
              };
            };
          };
          defaultSession = "plasmawayland";
        };
      };

      environment = {
        systemPackages = with pkgs; [
          kdePackages.plasma-keyboard
          kdePackages.krohnkite
          klassy
        ];
        plasma6.excludePackages = with pkgs.kdePackages; [
          oxygen
          kate
          konsole
          discover
        ];
      };
    };

  # https://nix-community.github.io/plasma-manager/options.xhtml
  flake.modules.homeManager.kde =
    { lib, ... }:
    {
      imports = [ inputs.self.modules.homeManager.plasma-manager ];

      programs.plasma = {
        enable = true;
        immutableByDefault = true;
        overrideConfig = true;

        powerdevil = {
          AC = {
            whenLaptopLidClosed = "doNothing";
            inhibitLidActionWhenExternalMonitorConnected = true;
          };
        };

        configFile.kdeglobals = {
          General = {
            Name.value = "Breeze Dark";
            shadeSortColumn.value = true;
            TerminalApplication.value = "ghostty";
            TerminalService.value = "com.mitchellh.ghostty.desktop";
          };
          # "Colors:View" = {
          #   BackgroundAlternate.value = "49,54,59";
          #   BackgroundNormal.value = "35,38,41";
          #   DecorationFocus.value = "61,174,233";
          #   DecorationHover.value = "61,174,233";
          #   ForegroundActive.value = "61,174,233";
          #   ForegroundInactive.value = "161,169,177";
          #   ForegroundLink.value = "29,153,243";
          #   ForegroundNegative.value = "218,68,83";
          #   ForegroundNeutral.value = "246,116,0";
          #   ForegroundNormal.value = "239,240,241";
          #   ForegroundPositive.value = "39,174,96";
          #   ForegroundVisited.value = "155,89,182";
          # };
          # "Colors:Window" = {
          #   BackgroundAlternate.value = "49,54,59";
          #   BackgroundNormal.value = "49,54,59";
          #   DecorationFocus.value = "61,174,233";
          #   DecorationHover.value = "61,174,233";
          #   ForegroundActive.value = "61,174,233";
          #   ForegroundInactive.value = "161,169,177";
          #   ForegroundLink.value = "29,153,243";
          #   ForegroundNegative.value = "218,68,83";
          #   ForegroundNeutral.value = "246,116,0";
          #   ForegroundNormal.value = "239,240,241";
          #   ForegroundPositive.value = "39,174,96";
          #   ForegroundVisited.value = "155,89,182";
          # };
          # "Colors:Button" = {
          #   BackgroundAlternate.value = "49,54,59";
          #   BackgroundNormal.value = "49,54,59";
          #   DecorationFocus.value = "61,174,233";
          #   DecorationHover.value = "61,174,233";
          #   ForegroundActive.value = "61,174,233";
          #   ForegroundInactive.value = "161,169,177";
          #   ForegroundLink.value = "29,153,243";
          #   ForegroundNegative.value = "218,68,83";
          #   ForegroundNeutral.value = "246,116,0";
          #   ForegroundNormal.value = "239,240,241";
          #   ForegroundPositive.value = "39,174,96";
          #   ForegroundVisited.value = "155,89,182";
          # };
          # "Colors:Selection" = {
          #   BackgroundAlternate.value = "29,153,243";
          #   BackgroundNormal.value = "61,174,233";
          #   DecorationFocus.value = "61,174,233";
          #   DecorationHover.value = "61,174,233";
          #   ForegroundActive.value = "252,252,252";
          #   ForegroundInactive.value = "161,169,177";
          #   ForegroundLink.value = "253,188,75";
          #   ForegroundNegative.value = "218,68,83";
          #   ForegroundNeutral.value = "246,116,0";
          #   ForegroundNormal.value = "252,252,252";
          #   ForegroundPositive.value = "39,174,96";
          #   ForegroundVisited.value = "155,89,182";
          # };
          # "Colors:Tooltip" = {
          #   BackgroundAlternate.value = "49,54,59";
          #   BackgroundNormal.value = "49,54,59";
          #   DecorationFocus.value = "61,174,233";
          #   DecorationHover.value = "61,174,233";
          #   ForegroundActive.value = "61,174,233";
          #   ForegroundInactive.value = "161,169,177";
          #   ForegroundLink.value = "29,153,243";
          #   ForegroundNegative.value = "218,68,83";
          #   ForegroundNeutral.value = "246,116,0";
          #   ForegroundNormal.value = "239,240,241";
          #   ForegroundPositive.value = "39,174,96";
          #   ForegroundVisited.value = "155,89,182";
          # };
          # "Colors:Complementary" = {
          #   BackgroundAlternate.value = "49,54,59";
          #   BackgroundNormal.value = "42,46,50";
          #   DecorationFocus.value = "61,174,233";
          #   DecorationHover.value = "61,174,233";
          #   ForegroundActive.value = "61,174,233";
          #   ForegroundInactive.value = "161,169,177";
          #   ForegroundLink.value = "29,153,243";
          #   ForegroundNegative.value = "218,68,83";
          #   ForegroundNeutral.value = "246,116,0";
          #   ForegroundNormal.value = "239,240,241";
          #   ForegroundPositive.value = "39,174,96";
          #   ForegroundVisited.value = "155,89,182";
          # };
        };

        # https://github.com/nix-community/plasma-manager/blob/trunk/modules/workspace.nix
        workspace = {
          clickItemTo = "select";
          wallpaperPlainColor = "0,0,0";
          colorScheme = "BreezeDark";
          windowDecorations = {
            library = "org.kde.klassy";
            theme = "Klassy";
          };
          cursor = {
            theme = "breeze_cursors";
            cursorFeedback = "Bouncing";
            taskManagerFeedback = true;
          };
          iconTheme = "breeze-dark";
          soundTheme = "ocean";
          widgetStyle = "breeze";
          splashScreen = {
            engine = "none";
            theme = "None";
          };
        };

        kwin = {
          effects = {
            cube.enable = false;
            desktopSwitching.animation = "off";
            minimization.animation = "off";
            windowOpenClose.animation = "off";
          };
          virtualDesktops = {
            names = null;
            number = null;
            rows = null;
          };
        };

        configFile."kwinrc"."Plugins"."krohnkiteEnabled".value = true;

        # https://github.com/nix-community/plasma-manager/blob/trunk/modules/panels.nix
        panels = [
          {
            location = "bottom";
            height = 48;
            lengthMode = "fit";
            alignment = "center";
            hiding = "autohide";
            floating = true;
            opacity = "adaptive";
            widgets = [
              "org.kde.plasma.kickoff"
              "org.kde.plasma.pager"
              {
                iconTasks.launchers = [
                  "applications:systemsettings.desktop"
                  "applications:org.kde.dolphin.desktop"
                  "applications:google-chrome.desktop"
                  "applications:com.mitchellh.ghostty.desktop"
                  "applications:vesktop.desktop"
                  "applications:steam.desktop"
                  "applications:teams-for-linux.desktop"
                ];
              }
              "org.kde.plasma.marginsseparator"
              "org.kde.plasma.systemtray"
              "org.kde.plasma.digitalclock"
              "org.kde.plasma.showdesktop"
            ];
          }
        ];

        input = {
          keyboard = {
            repeatRate = 67.0;
            repeatDelay = 195;
          };

          # ~/.config/kcminputrc has the [vendorId] and [productId]
          touchpads = [
            {
              name = "SYNA2BA6:00 06CB:CFD8 Touchpad";
              naturalScroll = true;
              pointerSpeed = 0;
              vendorId = "1739";
              productId = "53208";
            }
          ];

          # ~/.config/kcminputrc has the [vendorId] and [productId]
          mice = [
            {
              name = "SYNA2BA6:00 06CB:CFD8 Mouse";
              accelerationProfile = "none";
              acceleration = 0.0;
              scrollSpeed = 1;
              vendorId = "1739";
              productId = "53208";
            }
          ];
        };

        session = {
          general.askForConfirmationOnLogout = false;
          sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
        };

        # ~/.config/kglobalshortcutsrc
        shortcuts = {
          ksmserver = {
            "Lock Session" = [
              "Screensaver"
              "Meta+Z"
            ];
          };

          kwin = {
            "Window Fullscreen" = "Meta+O";
            "Window Close" = "Meta+Q";
            # Krohnkite
            "Krohnkite: Focus Next Window" = "Meta+.";
            "Krohnkite: Focus Previous Window" = "Meta+,";
            "Krohnkite: Focus Down" = "Meta+J";
            "Krohnkite: Focus Up" = "Meta+K";
            "Krohnkite: Focus Left" = "Meta+H";
            "Krohnkite: Focus Right" = "Meta+L";
            "Krohnkite: Move Window Down/Next" = "Meta+Shift+J";
            "Krohnkite: Move Window Up/Previous" = "Meta+Shift+K";
            "Krohnkite: Move Window Left" = "Meta+Shift+H";
            "Krohnkite: Move Window Right" = "Meta+Shift+L";
            "Krohnkite: Increase Window Width" = "Meta+I";
            "Krohnkite: Decrease Window Width" = "Meta+D";
            "Krohnkite: Toggle Float" = "Meta+F";
            "Krohnkite: Next Layout" = "Meta+\\";
            "Krohnkite: Previous Layout" = "Meta+|";
            "Krohnkite: Set as Master" = "Meta+Return";
            "Krohnkite: Use Monocle Layout" = "Meta+Shift+M";
          };

          "com.mitchellh.ghostty.desktop" = {
            "new-window" = "Meta+T";
          };

          "google-chrome.desktop" = {
            "new-window" = "Meta+B";
            "new-private-window" = [ ];
          };

          "teams-for-linux.desktop" = {
            "_launch" = "Meta+M";
          };

          "org.kde.dolphin.desktop" = {
            "_launch" = "Meta+E";
          };

          "1password.desktop" = {
            "_launch" = "Meta+P";
          };
        };
      };

      home.file.".config/klassy/klassyrc".text = lib.generators.toINI { } {
        Exceptions = {
          BorderSize = "Tiny";
          ExceptionBorder = true;
          ExceptionWindowPropertyPattern = ".*";
          ExceptionWindowPropertyType = "ExceptionWindowTitle";
          HideTitleBar = true;
          OpaqueTitleBar = true;
        };
        Global = {
          LookAndFeelSet = "org.kde.klassydarkleftpanel.desktop";
        };
        TitleBarSpacing = {
          PercentMaximizedTopBottomMargins = 0;
          TitleBarBottomMargin = 0;
          TitleBarTopMargin = 0;
          TitleSidePadding = 30;
        };
        Windeco = {
          AnimationsEnabled = false;
          AnimationsSpeedRelativeSystem = 6;
          ButtonIconStyle = "StyleKite";
          ButtonShape = "ShapeFullHeightRoundedRectangle";
          CornerRadius = 6;
          DrawBorderOnMaximizedWindows = true;
          RoundBottomCornersWhenNoBorders = true;
        };
        "Windeco Exception 0" = {
          BorderSize = 2;
          Enabled = true;
          ExceptionBorder = true;
          ExceptionPreset = "";
          ExceptionProgramNamePattern = "";
          ExceptionWindowPropertyPattern = ".*";
          ExceptionWindowPropertyType = 1;
          HideTitleBar = true;
          OpaqueTitleBar = true;
          PreventApplyOpacityToHeader = false;
        };
        WindowOutlineStyle = {
          LockThinWindowOutlineCustomColorActiveInactive = false;
          ThinWindowOutlineCustomColorActive = "193,145,255";
          ThinWindowOutlineCustomColorInactive = "90,90,90";
          ThinWindowOutlineStyleActive = "WindowOutlineCustomColor";
          ThinWindowOutlineStyleInactive = "WindowOutlineCustomColor";
          ThinWindowOutlineThickness = 4;
          WindowOutlineAccentWithContrastOpacityInactive = 61;
          WindowOutlineCustomColorOpacityActive = 100;
          WindowOutlineCustomColorOpacityInactive = 100;
        };
      };
    };
}
