{
  inputs,
  ...
}:

{
  flake.modules.nixos.system-default =
    { lib, pkgs, ... }:
    {
      imports =
        (with inputs.self.modules.nixos; [
          system-base
          fonts
        ])
        ++ [
          inputs.nix-flatpak.nixosModules.nix-flatpak
        ];

      time.timeZone = "Australia/Perth";
      i18n.defaultLocale = "en_AU.UTF-8";

      boot = {
        kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
          timeout = 1;
        };
      };

      services = {
        blueman.enable = true;
        power-profiles-daemon.enable = true;
        xserver.xkb.layout = "us";
        flatpak.enable = true;
      };

      hardware = {
        keyboard.zsa.enable = true;
        enableRedistributableFirmware = true;
        bluetooth = {
          enable = true;
          package = pkgs.bluez;
        };
      };

      networking.networkmanager = {
        enable = true;
        # NOTE: Prevents wifi sleeping when lid is shut
        wifi.powersave = false;
      };

      programs = {
        _1password.enable = true;
        _1password-gui = {
          enable = true;
          polkitPolicyOwners = [ "mbwilding" ];
        };
        fish.enable = true;
        mtr.enable = true;
        nano.enable = false;
        nix-ld.enable = true;
        bazecor = {
          enable = true;
          package = pkgs.bazecor.overrideAttrs (old: {
            buildCommand =
              lib.replaceStrings
                [
                  "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true"
                ]
                [ "--ozone-platform=x11" ]
                old.buildCommand;
          });
        };
      };

      environment = {
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          ELECTRON_OZONE_PLATFORM_HINT = "wayland";
          NIXPKGS_ALLOW_INSECURE = 1;
          NIXPKGS_ALLOW_UNFREE = 1;
        };
        etc."1password/custom_allowed_browsers" = {
          text = ''
            google-chrome
          '';
          mode = "0755";
        };
      };

      nixpkgs = {
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "pnpm-10.34.0"
          ];
        };
      };

      nix = {
        settings = {
          auto-optimise-store = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          download-buffer-size = 5 * 1024 * 1024 * 1024;
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
      };
    };
}
