{ ... }:

# https://nix-community.github.io/plasma-manager/options.xhtml

{
  programs.plasma = {
    enable = true;
    immutableByDefault = true;
    resetFiles = [ "kglobalshortcutsrc" ];

    powerdevil = {
      AC = {
        whenLaptopLidClosed = "doNothing";
        inhibitLidActionWhenExternalMonitorConnected = true;
      };
    };

    # https://github.com/nix-community/plasma-manager/blob/trunk/modules/workspace.nix
    workspace = {
      clickItemTo = "select";
      wallpaperPlainColor = "0,0,0";
      # lookAndFeel = "org.kde.breezedark.desktop";
      colorScheme = "BreezeDark";
      cursor = {
        theme = "breeze_cursors";
        cursorFeedback = "Bouncing";
        taskManagerFeedback = true;
      };
      iconTheme = "breeze-dark";
      soundTheme = "ocean";
      windowDecorations = {
        library = "org.kde.breeze";
        theme = "Breeze";
      };
      widgetStyle = "breeze";
      splashScreen = {
        engine = "none";
        theme = "None";
      };
      # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/1080x1920.png";
    };

    kwin = {
      effects = {
        cube.enable = false;
        desktopSwitching.animation = "off";
        minimization.animation = "off";
        windowOpenClose.animation = "off";
      };
      virtualDesktops = {
        names = null; # [""]
        number = null; # int
        rows = null; # int
      };
    };

    # https://github.com/nix-community/plasma-manager/blob/trunk/modules/panels.nix
    panels = [
      {
        location = "bottom";
        height = 44;
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
              "applications:discord.desktop"
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
        # "Switch Window Down" = "Meta+J";
        # "Switch Window Left" = "Meta+H";
        # "Switch Window Right" = "Meta+L";
        # "Switch Window Up" = "Meta+K";
      };

      "com.mitchellh.ghostty.desktop" = {
        "new-window" = "Meta+T";
      };

      "google-chrome.desktop" = {
        "new-window" = "Meta+B";
        "new-private-window" = "Meta+I";
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
}
