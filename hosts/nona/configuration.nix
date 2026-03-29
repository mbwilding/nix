{ ... }:

let
  keymap = "dvorak";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/amd.nix

    # ../../modules/system/kde.nix
    ../../modules/system/hyprland.nix

    ../../modules/system/default.nix
    ../../modules/system/mounts.nix
    ../../modules/system/podman.nix
    # ../../modules/system/docker.nix
    ../../modules/system/steam.nix
    ../../modules/system/wireguard.nix
    ../../modules/system/wireshark.nix
    ../../modules/system/appimage.nix
    ../../modules/system/waydroid.nix
  ];

  networking.hostName = "nona";

  console.keyMap = keymap;
  services.xserver.xkb.variant = keymap;

  hardware = {
    xone.enable = true;
  };

  services = {
    upower.enable = true;

    keyd = {
      enable = true;
      keyboards.default = {
        ids = [
          "0001:0001:09b4e68d"
          "413c:2110:a6c37897"
        ];

        settings = {
          main = {
            backspace = "noop";
            space = "overload(shift, space)";
            capslock = "overload(capslock, backspace)";
            leftshift = "esc";
            rightalt = "layer(symbols)";

            a = "overloadt(control, a, 200)";
            ";" = "overloadt(control, ;, 200)";
            s = "overloadt(meta, s, 200)";
            l = "overloadt(meta, l, 200)";
            z = "overloadt(alt, z, 200)";
            "/" = "overloadt(alt, /, 200)";
            f = "overloadt(numbers, f, 200)";
            m = "overloadt(fkeys, m, 200)";
          };

          "capslock:C" = {
            j = "left";
            c = "down";
            v = "up";
            p = "right";
          };

          "capslock+shift" = {
            j = "C-left";
            c = "C-down";
            v = "C-up";
            p = "C-right";
          };

          symbols = {
            q = "`";
            w = "!";
            e = "?";
            r = "@";
            t = "{";
            y = "}";
            u = "~";
            p = "right";
            a = "=";
            s = "|";
            d = "^";
            f = "_";
            g = "(";
            h = ")";
            j = "left";
            k = "$";
            l = "&";
            ";" = "-";
            z = "/";
            x = "#";
            c = "down";
            v = "up";
            b = "{";
            n = "}";
            m = "+";
            "," = "%";
            "." = "*";
            "/" = "\\";
          };

          numbers = {
            ";" = "0";
            m = "1";
            "," = "2";
            "." = "3";
            j = "4";
            k = "5";
            l = "6";
            u = "7";
            i = "8";
            o = "9";
          };

          fkeys = {
            q = "f1";
            w = "f2";
            e = "f3";
            r = "f4";
            a = "f5";
            s = "f6";
            d = "f7";
            f = "f8";
            z = "f9";
            x = "f10";
            c = "f11";
            v = "f12";
          };
        };
      };
    };
  };

  services.pipewire.wireplumber.extraConfig."99-rename-devices" = {
    "monitor.alsa.rules" = [
      {
        matches = [ { "device.name" = "alsa_card.pci-0000_c1_00.1"; } ];
        actions.update-props = {
          "device.description" = "HDMI";
          "device.nick" = "HDMI";
        };
      }
      {
        matches = [ { "device.name" = "alsa_card.platform-snd_aloop.0"; } ];
        actions.update-props = {
          "device.description" = "Loopback";
          "device.nick" = "OBS Loopback";
        };
      }
      {
        matches = [ { "node.name" = "alsa_output.pci-0000_c1_00.6.HiFi__Speaker__sink"; } ];
        actions.update-props = {
          "node.description" = "Laptop";
          "node.nick" = "Internal Speakers";
        };
      }
      {
        matches = [ { "node.name" = "alsa_input.pci-0000_c1_00.6.HiFi__Mic2__source"; } ];
        actions = {
          update-props = {
            "node.description" = "Laptop";
            "node.nick" = "Internal Mics";
            "node.disabled" = true;
          };
        };
      }
      {
        matches = [ { "node.name" = "alsa_input.pci-0000_c1_00.6.HiFi__Mic1__source"; } ];
        actions.update-props = {
          "node.description" = "Laptop";
          "node.nick" = "Internal Mics (Digital)";
        };
      }
      {
        matches = [ { "node.name" = "alsa_output.platform-snd_aloop.0.analog-stereo"; } ];
        actions.update-props = {
          "node.description" = "Loopback";
          "node.nick" = "OBS Loopback";
        };
      }
      {
        matches = [ { "node.name" = "alsa_input.platform-snd_aloop.0.analog-stereo"; } ];
        actions.update-props = {
          "node.description" = "Loopback";
          "node.nick" = "OBS Loopback (Monitor)";
        };
      }
    ];
  };

  environment = {
    sessionVariables = {
      WAYLANDDRV_PRIMARY_MONITOR = "eDP-1";
    };
  };

  system.stateVersion = "25.11";
}
