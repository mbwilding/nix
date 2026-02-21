{ inputs, pkgs, hostname, ... }:

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
      {
        output = "DP-1";
        mode = "2560x1080@60";
        position = "-1080x0";
        scale = 1.0;
        transform = 3;
      }
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
      # wofi
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
      inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprbars
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
        cm_fs_passthrough = 1; # This may cause blown out colors
        cm_auto_hdr = 2;
        new_render_scheduling = false;
      };

      exec-once = [
        "brightnessctl set --device=platform::micmute 0"
        # "nm-applet"
        # "hyprpaper"
        # "hyprpanel"
        # "hypridle"
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
        "$mod, Y, exec, home-manager switch -b backup --impure --flake ~/nix#anon"

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

      monitorv2 = monitors.${hostname} or [];

      input = {
        kb_layout = "us";
        kb_variant = "dvorak";

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
    };
  };

  # home.pointerCursor = {
  #   gtk.enable = true;
  #   # x11.enable = true;
  #   package = pkgs.bibata-cursors;
  #   name = "Bibata-Modern-Classic";
  #   size = 16;
  # };
  #
  # gtk = {
  #   enable = true;
  #
  #   theme = {
  #     package = pkgs.flat-remix-gtk;
  #     name = "Flat-Remix-GTK-Grey-Darkest";
  #   };
  #
  #   iconTheme = {
  #     package = pkgs.adwaita-icon-theme;
  #     name = "Adwaita";
  #   };
  #
  #   font = {
  #     name = "Sans";
  #     size = 11;
  #   };
  # };

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
  };
}
