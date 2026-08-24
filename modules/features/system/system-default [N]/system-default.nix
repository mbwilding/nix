{
  inputs,
  ...
}:

{
  flake.modules.nixos.system-default =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = with inputs.self.modules.nixos; [
        system-base
        fonts
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
        initrd.systemd.enable = true;
      };

      services = {
        blueman.enable = true;
        power-profiles-daemon.enable = true;
        xserver.xkb.layout = "us";
      };

      hardware = {
        keyboard.zsa.enable = true;
        enableRedistributableFirmware = true;
        bluetooth = {
          enable = true;
          package = pkgs.bluez;
        };
      };

      networking = {
        domain = "localdomain";
        networkmanager = {
          enable = true;
          # NOTE: Prevents wifi sleeping when lid is shut
          wifi.powersave = false;
        };
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
      };

      system.activationScripts.binbash = lib.stringAfter [ "binsh" ] ''
        if [ ! -e /bin/bash ]; then
          ln -sf ${pkgs.bash}/bin/bash /bin/bash
        fi
      '';

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
            firefox
          '';
          mode = "0755";
        };
        etc."gitconfig".text = ''
          [safe]
            directory = /etc/nixos
        '';
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
