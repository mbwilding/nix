{ pkgs, secrets, ... }:

{
  imports = [
    ./fonts.nix
  ];

  services = {
    ucodenix.enable = true;
    blueman.enable = true;
    power-profiles-daemon.enable = true;
    xserver.xkb = {
      layout = "us";
    };
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
  };

  # 32x64 16x32 12x24 8x16 6x12 5x8
  console.font = "${pkgs.spleen}/share/consolefonts/spleen-16x32.psfu";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_zen;
  };

  time.timeZone = "Australia/Perth";

  i18n = {
    defaultLocale = "en_AU.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_AU.UTF-8";
      LC_IDENTIFICATION = "en_AU.UTF-8";
      LC_MEASUREMENT = "en_AU.UTF-8";
      LC_MONETARY = "en_AU.UTF-8";
      LC_NAME = "en_AU.UTF-8";
      LC_NUMERIC = "en_AU.UTF-8";
      LC_PAPER = "en_AU.UTF-8";
      LC_TELEPHONE = "en_AU.UTF-8";
      LC_TIME = "en_AU.UTF-8";
    };
  };

  networking = {
    networkmanager = {
      enable = true;
      ensureProfiles.profiles = {
        home = {
          connection = {
            id = secrets.wifiHomeSsid;
            type = "wifi";
          };
          wifi = {
            mode = "infrastructure";
            ssid = secrets.wifiHomeSsid;
          };
          wifi-security = {
            key-mgmt = "sae";
            psk = secrets.wifiHomePassword;
          };
          ipv4.method = "auto";
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
        };
        parents = {
          connection = {
            id = secrets.wifiParentsSsid;
            type = "wifi";
          };
          wifi = {
            mode = "infrastructure";
            ssid = secrets.wifiParentsSsid;
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = secrets.wifiParentsPassword;
          };
          ipv4.method = "auto";
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
        };
      };
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez;
  };

  users.users.anon = {
    description = "anon";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "docker"
    ];
    isNormalUser = true;
    shell = pkgs.fish;
  };

  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
    systemPackages = with pkgs; [
      _1password-cli
      cacert
      cifs-utils
      coreutils
      icu
      kdePackages.partitionmanager

      # Only for building things
      pkg-config
      openssl
    ];
  };

  programs = {
    bazecor.enable = true;
    fish.enable = true;
    zsh.enable = false;
    mtr.enable = true;
    nano.enable = false;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "anon" ];
    };
    # Needed for running dynamically linked binaries
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ icu ];
    };
  };

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        google-chrome
      '';
      mode = "0755";
    };
  };

  environment = {
    sessionVariables = {
      # SDL_VIDEODRIVER = "wayland";
      # QT_QPA_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    };
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  system = {
    autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };
}
