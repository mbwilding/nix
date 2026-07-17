{ inputs, ... }:

{
  flake.modules.nixos.niri =
    { pkgs, ... }:
    {
      imports = [
        inputs.self.modules.nixos.wayland-session
        inputs.self.modules.nixos.udiskie
      ];

      config = {
        host.waylandSession.sessionPackage = pkgs.niri;

        programs.niri = {
          enable = true;
          # xwayland is handled via programs.xwayland below
        };

        programs.xwayland.enable = true;

        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gnome
            pkgs.xdg-desktop-portal-gtk
          ];
          config.niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
          };
        };

        services.gnome.gnome-keyring.enable = true;

        environment.systemPackages = [ pkgs.polkit_gnome ];
      };
    };

  flake.modules.homeManager.niri =
    {
      lib,
      pkgs,
      osConfig ? null,
      primaryMonitor ? (if osConfig != null then osConfig.host.primaryMonitor else ""),
      ...
    }:

    let
      screenshotDir = "${import ../../../nix/_home.nix}/Pictures/Screenshots";
      mod = "Mod";
    in
    {
      imports = [
        inputs.niri.homeModules.config
        inputs.self.modules.homeManager.noctalia
        inputs.self.modules.homeManager.udiskie
        inputs.self.modules.homeManager.desktop-theme
      ];

      home.packages = with pkgs; [
        jq
        pulseaudio
        swayimg # image viewer (imv equivalent for niri)
        wl-clipboard
        grim
        slurp
      ];

      programs.niri.settings = {
        hotkey-overlay.skip-at-startup = true;

        screenshot-path = screenshotDir + "/Screenshot from %Y-%m-%d %H-%M-%S.png";

        input = {
          keyboard = {
            xkb = {
              layout = "us";
              variant = "dvorak";
            };
            repeat-rate = 63;
            repeat-delay = 195;
          };

          mouse = {
            accel-profile = "flat";
            natural-scroll = false;
          };

          touchpad = {
            natural-scroll = true;
            tap = true;
            dwt = false;
          };

          focus-follows-mouse.enable = false;
        };

        cursor = {
          theme = "breeze_cursors";
          size = 24;
        };

        layout = {
          gaps = 0;
          border.enable = false;
          focus-ring.enable = false;
          shadow.enable = false;
          default-column-width = { proportion = 0.5; };

          struts = {
            left = 0;
            right = 0;
            top = 0;
            bottom = 0;
          };
        };

        animations = {
          slowdown = 0.5;
        };

        prefer-no-csd = true;

        environment = {
          CLUTTER_BACKEND = "wayland";
          ELECTRON_OZONE_PLATFORM_HINT = "wayland";
          GDK_BACKEND = "wayland,x11,*";
          QT_QPA_PLATFORM = "wayland;xcb";
          SDL_VIDEODRIVER = "wayland";
          XDG_CURRENT_DESKTOP = "niri";
          XDG_SESSION_DESKTOP = "niri";
          XDG_SESSION_TYPE = "wayland";
          NIXOS_OZONE_WL = "1";
        };

        spawn-at-startup = [
          { command = [ "noctalia" ]; }
          { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
        ];

        # Per-host outputs/workspaces/window-rules are added via lib.mkAfter in _niri.nix overlays.
        outputs = { };
        workspaces = { };

        binds =
          {
            # Applications
            "${mod}+B".action.spawn = [ "google-chrome" ];
            "${mod}+C".action.spawn = [
              "ghostty"
              "-e"
              "btop"
            ];
            "${mod}+D".action.spawn = [ "vesktop" ];
            "${mod}+E".action.spawn = [
              "ghostty"
              "-e"
              "yazi"
            ];
            "${mod}+M".action.spawn = [ "teams-for-linux" ];
            "${mod}+P".action.spawn = [ "1password" ];
            "${mod}+R".action.spawn = [
              "noctalia"
              "msg"
              "panel-toggle"
              "launcher"
            ];
            "${mod}+S".action.spawn = [ "spotify" ];
            "${mod}+T".action.spawn = [ "ghostty" ];
            "${mod}+Z".action.spawn = [
              "noctalia"
              "msg"
              "session"
              "lock"
            ];
            "${mod}+G".action.spawn = [
              "systemd-run"
              "--user"
              "--scope"
              "steam"
              "-beta"
              "publicbeta"
            ];
            "${mod}+Comma".action.spawn = [
              "noctalia"
              "msg"
              "settings-toggle"
            ];
            "${mod}+Minus".action.spawn = [ "sh" "-c" "ecc toggle" ];

            # Window management
            "${mod}+F".action.toggle-window-floating = { };
            "${mod}+O".action.maximize-column = { };
            "${mod}+Q".action.close-window = { };
            "${mod}+grave".action.quit.skip-confirmation = true;

            # Screenshots
            "${mod}+Semicolon".action.screenshot-window = { };
            "${mod}+Apostrophe".action.screenshot = { };
            "Print".action.screenshot-screen = { };

            # Focus (vim hjkl)
            "${mod}+H".action.focus-column-left = { };
            "${mod}+L".action.focus-column-right = { };
            "${mod}+K".action.focus-window-up = { };
            "${mod}+J".action.focus-window-down = { };

            # Move windows
            "${mod}+Shift+H".action.move-column-left = { };
            "${mod}+Shift+L".action.move-column-right = { };
            "${mod}+Shift+K".action.move-window-up = { };
            "${mod}+Shift+J".action.move-window-down = { };

            # Workspaces (Dvorak home row: h=1 t=2 n=3 s=4 minus=5)
            "${mod}+Ctrl+H".action.focus-workspace = 1;
            "${mod}+Ctrl+T".action.focus-workspace = 2;
            "${mod}+Ctrl+N".action.focus-workspace = 3;
            "${mod}+Ctrl+S".action.focus-workspace = 4;
            "${mod}+Ctrl+Minus".action.focus-workspace = 5;
            "${mod}+Ctrl+Shift+H".action.move-window-to-workspace = 1;
            "${mod}+Ctrl+Shift+T".action.move-window-to-workspace = 2;
            "${mod}+Ctrl+Shift+N".action.move-window-to-workspace = 3;
            "${mod}+Ctrl+Shift+S".action.move-window-to-workspace = 4;
            "${mod}+Ctrl+Shift+Minus".action.move-window-to-workspace = 5;
            "${mod}+6".action.focus-workspace = "social";
            "${mod}+7".action.focus-workspace = "spare";
            "${mod}+Shift+6".action.move-window-to-workspace = "social";
            "${mod}+Shift+7".action.move-window-to-workspace = "spare";

            # Column sizing
            "${mod}+I".action.set-column-width = "+5%";
            "${mod}+Shift+I".action.set-column-width = "-5%";

            # Media keys
            "XF86AudioMute" = {
              action.spawn = [
                "pactl"
                "set-sink-mute"
                "@DEFAULT_SINK@"
                "toggle"
              ];
              allow-when-locked = true;
            };
            "XF86AudioMicMute" = {
              action.spawn = [
                "pactl"
                "set-source-mute"
                "@DEFAULT_SOURCE@"
                "toggle"
              ];
              allow-when-locked = true;
            };
            "XF86AudioLowerVolume" = {
              action.spawn = [
                "pactl"
                "set-sink-volume"
                "@DEFAULT_SINK@"
                "-5%"
              ];
              repeat = true;
            };
            "XF86AudioRaiseVolume" = {
              action.spawn = [
                "pactl"
                "set-sink-volume"
                "@DEFAULT_SINK@"
                "+5%"
              ];
              repeat = true;
            };
            "XF86MonBrightnessDown" = {
              action.spawn = [
                "brightnessctl"
                "set"
                "5%-"
              ];
              repeat = true;
            };
            "XF86MonBrightnessUp" = {
              action.spawn = [
                "brightnessctl"
                "set"
                "+5%"
              ];
              repeat = true;
            };
          };

        switch-events = {
          lid-close.action.spawn = [
            "sh"
            "-c"
            "noctalia msg session lock && niri msg action power-off-monitors && [ $(cat /sys/class/power_supply/AC/online) -eq 0 ] && systemctl suspend"
          ];
          lid-open.action.spawn = [
            "niri"
            "msg"
            "action"
            "power-on-monitors"
          ];
        };
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "image/png" = "swayimg.desktop";
          "image/jpeg" = "swayimg.desktop";
          "image/gif" = "swayimg.desktop";
          "image/bmp" = "swayimg.desktop";
          "image/svg+xml" = "swayimg.desktop";
          "image/tiff" = "swayimg.desktop";
          "image/webp" = "swayimg.desktop";
          "image/x-icon" = "swayimg.desktop";
        };
      };
    };
}
