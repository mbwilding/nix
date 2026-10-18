{ inputs, ... }:

{
  flake.modules.nixos.mango =
    { pkgs, ... }:
    {
      imports = [
        inputs.mango.nixosModules.mango
        inputs.self.modules.nixos.wayland-session
        inputs.self.modules.nixos.udiskie
      ];

      config = {
        programs.mango.enable = true;
        host.waylandSession.sessionPackage = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango;

        programs.xwayland.enable = true;

        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          config.common = {
            default = [ "gtk" ];
          };
        };

        programs.dconf.enable = true;

        services = {
          gnome.gnome-keyring.enable = true;
          tumbler.enable = true;
        };

        environment.systemPackages = [ pkgs.polkit_gnome ];
      };
    };

  flake.modules.homeManager.mango =
    {
      lib,
      config,
      pkgs,
      ...
    }:

    let
      screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";
      terminal = "kitty";
      mod = "SUPER";

      toggleHdr = pkgs.writeShellScript "toggle-hdr" ''
        exec 9>"$XDG_RUNTIME_DIR/toggle-hdr.lock"
        ${pkgs.util-linux}/bin/flock -n 9 || exit 0
        m=$(mmsg get cursorpos | ${pkgs.jq}/bin/jq -r .monitor)
        mmsg dispatch "togglehdr,toggle,$m"
        sleep 0.3
        state=$(mmsg get monitor "$m" | ${pkgs.jq}/bin/jq -r 'if .is_hdr then "On" else "Off" end')
        noctalia msg notification-show "HDR $state" "$m"
        sleep 1
      '';

      spawn = key: cmd: "${mod},${key},spawn,${cmd}";
      shell = key: cmd: "${mod},${key},spawn_shell,${cmd}";

      # Dvorak home row: h=1 t=2 n=3 s=4 -=5
      workspaces = [
        {
          key = "h";
          tag = 1;
        }
        {
          key = "t";
          tag = 2;
        }
        {
          key = "n";
          tag = 3;
        }
        {
          key = "s";
          tag = 4;
        }
        {
          key = "minus";
          tag = 5;
        }
      ];
      extraWorkspaces = [
        {
          key = "6";
          tag = 6;
        }
        {
          key = "7";
          tag = 7;
        }
      ];
    in
    {
      imports = [
        inputs.mango.hmModules.mango
        inputs.self.modules.homeManager.keymap
        inputs.self.modules.homeManager.noctalia
        inputs.self.modules.homeManager.udiskie
        inputs.self.modules.homeManager.desktop-theme
      ];

      home.packages = with pkgs; [
        grim
        jq
        pulseaudio
        slurp
        wl-clipboard
      ];

      wayland.windowManager.mango = {
        enable = true;
        systemd = {
          enable = true;
          variables = [ "--all" ];
        };

        settings = {
          # Layout (master-stack, master on the left, new windows join the stack)
          tag_rule = map (n: "id:${toString n},layout_name:tile") (lib.range 1 9);
          new_is_master = 0;
          default_master_factor = 0.5;
          default_master_count = 1;
          tag_num = 9;

          # Appearance
          border_px = 0;
          gap_inner_horizontal = 0;
          gap_inner_vertical = 0;
          gap_outer_horizontal = 0;
          gap_outer_vertical = 0;
          focused_opacity = 1.0;
          unfocused_opacity = 1.0;

          animations = 1;
          layer_animations = 0;
          animation_duration_open = 200;
          animation_duration_close = 200;
          animation_duration_move = 200;
          animation_duration_tag = 0;
          animation_type_open = "zoom";
          animation_type_close = "zoom";

          # Input
          xkb_rules_layout = "us";
          xkb_rules_variant = config.keymap.xkbVariant;
          repeat_rate = 63;
          repeat_delay = 195;
          numlock_on = 0;
          sloppy_focus = 0;
          warp_cursor = 0;
          cursor_hide_on_keypress = 1;
          mouse_accel_profile = 1;
          mouse_accel_speed = 0.0;
          trackpad_natural_scrolling = 1;
          trackpad_disable_while_typing = 0;
          tap_to_click = 1;

          # Rendering
          xwayland_persistence = 1;
          xwayland_ignore_scale = 1;

          env = [
            "CLUTTER_BACKEND,wayland"
            "ELECTRON_OZONE_PLATFORM_HINT,wayland"
            "GDK_BACKEND,wayland,x11,*"
            "GTK_THEME,Breeze-Dark"
            "QT_AUTO_SCREEN_SCALE_FACTOR,0"
            "QT_QPA_PLATFORM,wayland;xcb"
            "QT_QPA_PLATFORMTHEME,gtk3"
            "QT_SCALE_FACTOR,1"
            "SDL_VIDEODRIVER,wayland"
            "WLR_RENDERER,vulkan"
            "GDK_DPI_SCALE,1"
            "GDK_SCALE,1"
            "XCURSOR_SIZE,24"
            "XCURSOR_THEME,breeze_cursors"
          ];

          exec_once = [
            "noctalia"
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          ];

          window_rule = [
            # DaVinci Resolve
            "is_floating:1,app_id:^(resolve)$"
            "is_floating:0,app_id:^(resolve)$,title:^(DaVinci Resolve.*)$"
            # Steam
            "is_floating:0,app_id:^(steam)$,title:^(Steam)$"
          ];

          bind = [
            (spawn "b" "google-chrome")
            (spawn "c" "${terminal} -e btop")
            (spawn "d" "vesktop")
            (spawn "e" "thunar")
            (spawn "y" "${terminal} -e yazi")
            (spawn "m" "teams-for-linux")
            (spawn "p" "1password")
            (spawn "r" "noctalia msg panel-toggle launcher")
            (spawn "s" "spotify")
            (spawn "t" terminal)
            (spawn "x" "${toggleHdr}")
            (spawn "z" "noctalia msg session lock")
            (shell "g" "systemd-run --user --scope steam -beta publicbeta")
            (spawn "comma" "noctalia msg settings-toggle")
            (spawn "minus" "ecc toggle")

            "${mod},f,togglefloating"
            "${mod},o,togglefullscreen"
            "${mod},q,killclient"
            "${mod},grave,quit"

            (shell "semicolon" ''mkdir -p ${screenshotDir} && grim -g "$(slurp)" - | wl-copy'')
            (shell "apostrophe" ''mkdir -p ${screenshotDir} && grim -g "$(slurp)" ${screenshotDir}/$(date +%Y-%m-%d_%H-%M-%S).png'')
            "NONE,Print,spawn_shell,mkdir -p ${screenshotDir} && grim ${screenshotDir}/$(date +%Y-%m-%d_%H-%M-%S).png"

            # Focus
            "${mod},h,focusdir,left"
            "${mod},l,focusdir,right"
            "${mod},k,focusdir,up"
            "${mod},j,focusdir,down"

            # Swap
            "${mod}+SHIFT,h,exchange_client,left"
            "${mod}+SHIFT,l,exchange_client,right"
            "${mod}+SHIFT,k,exchange_client,up"
            "${mod}+SHIFT,j,exchange_client,down"

            # Master layout
            "${mod},n,focusstack,next"
            "${mod},Return,zoom"

            # Mod + scroll through tags
            "${mod},Right,viewtoright"
            "${mod},Left,viewtoleft"

            # Media (work when locked)
            "NONE,XF86AudioMute,spawn,pactl set-sink-mute @DEFAULT_SINK@ toggle"
            "NONE,XF86AudioMicMute,spawn,pactl set-source-mute @DEFAULT_SOURCE@ toggle"
            "NONE,XF86AudioLowerVolume,spawn,pactl set-sink-volume @DEFAULT_SINK@ -5%"
            "NONE,XF86AudioRaiseVolume,spawn,pactl set-sink-volume @DEFAULT_SINK@ +5%"
            "NONE,code:248,spawn,brightnessctl set --device=platform::kbd_backlight 5%-"
            "NONE,XF86Calculator,spawn,brightnessctl set --device=platform::kbd_backlight 5%+"
            "NONE,XF86MonBrightnessDown,spawn,brightnessctl set 5%-"
            "NONE,XF86MonBrightnessUp,spawn,brightnessctl set +5%"
          ]
          ++ map (w: "${mod}+CTRL,${w.key},view,${toString w.tag}") workspaces
          ++ map (w: "${mod}+CTRL+SHIFT,${w.key},tag,${toString w.tag}") workspaces
          ++ map (w: "${mod},${w.key},view,${toString w.tag}") extraWorkspaces
          ++ map (w: "${mod}+SHIFT,${w.key},tag,${toString w.tag}") extraWorkspaces;

          mousebind = [
            "${mod},btn_left,moveresize,curmove"
            "${mod},btn_right,moveresize,curresize"
          ];

          axisbind = [
            "${mod},UP,viewtoleft_have_client"
            "${mod},DOWN,viewtoright_have_client"
          ];

          gesturebind = [
            "none,up,3,viewtoleft_have_client"
            "none,down,3,viewtoright_have_client"
          ];

          switchbind = [
            "fold,spawn_shell,noctalia msg session lock && noctalia msg dpms-off && [ $(cat /sys/class/power_supply/AC/online) -eq 0 ] && systemctl suspend"
            "unfold,spawn,noctalia msg dpms-on"
          ];
        };
      };

      xdg = {
        # The imv package ships its .desktop entry with NoDisplay=true, which
        # hides it from file managers' "Open With" suggestion lists even when
        # it's the configured default. Override it with a visible entry.
        desktopEntries.imv = {
          name = "imv";
          genericName = "Image Viewer";
          comment = "Fast Image Viewer";
          exec = "imv %F";
          icon = "multimedia-photo-viewer";
          terminal = false;
          categories = [
            "Graphics"
            "2DGraphics"
            "Viewer"
          ];
          mimeType = [
            "image/png"
            "image/jpeg"
            "image/gif"
            "image/bmp"
            "image/svg+xml"
            "image/tiff"
            "image/webp"
            "image/x-icon"
          ];
        };

        mimeApps = {
          enable = true;
          defaultApplications = {
            "inode/directory" = "thunar.desktop";

            "image/png" = "imv.desktop";
            "image/jpeg" = "imv.desktop";
            "image/gif" = "imv.desktop";
            "image/bmp" = "imv.desktop";
            "image/svg+xml" = "imv.desktop";
            "image/tiff" = "imv.desktop";
            "image/webp" = "imv.desktop";
            "image/x-icon" = "imv.desktop";

            "video/mp4" = "mpv.desktop";
            "video/x-matroska" = "mpv.desktop";
            "video/webm" = "mpv.desktop";
            "video/quicktime" = "mpv.desktop";
            "video/x-msvideo" = "mpv.desktop";
            "video/mpeg" = "mpv.desktop";
            "video/ogg" = "mpv.desktop";
            "video/x-flv" = "mpv.desktop";
            "video/x-ms-wmv" = "mpv.desktop";
            "video/3gpp" = "mpv.desktop";
          };
        };
      };
    };
}
