{ pkgs, ... }:

let
  buildInputs = [
    "${pkgs.openssl.dev}/lib/pkgconfig"
    "${pkgs.wayland}/lib/pkgconfig"
    "${pkgs.wayland-protocols}/share/pkgconfig"
    "${pkgs.libxkbcommon}/lib/pkgconfig"
  ];
in
{
  imports = [
    ../../modules/system/fonts/fonts.nix
  ];

  networking.hostName = "wsl";

  services = {
    xserver.xkb = {
      layout = "us";
    };
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
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

  users.users.anon = {
    description = "anon";
    extraGroups = [
      "audio"
      "docker"
      "networkmanager"
      "render"
      "video"
      "wheel"
      "dialout"
    ];
    isNormalUser = true;
    shell = pkgs.fish;
  };

  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      # SDL_VIDEODRIVER = "wayland";
      # QT_QPA_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      NIXPKGS_ALLOW_UNFREE = 1;
      PKG_CONFIG_PATH = builtins.concatStringsSep ":" buildInputs;
    };
    systemPackages = with pkgs; [
      _1password-cli
      cacert
      cifs-utils
      coreutils
      icu
      libva
      libva-utils
      libxkbcommon
      openssl
      openssl.dev
      pkg-config
      skia
      wayland
      wayland-protocols
    ];
  };

  programs = {
    fish.enable = true;
    zsh.enable = false;
    mtr.enable = true;
    nano.enable = false;
    _1password.enable = true;
    # _1password-gui = {
    #   enable = true;
    #   polkitPolicyOwners = [ "anon" ];
    # };
    # Needed for running dynamically linked binaries
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ icu ];
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

  nix.settings = {
    download-buffer-size = 5 * 1024 * 1024 * 1024; # GB
  };

  system.stateVersion = "25.05";
}
