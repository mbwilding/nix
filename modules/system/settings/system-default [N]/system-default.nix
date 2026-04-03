{
  inputs,
  ...
}:
{
  # Desktop system defaults. Composes system-base and adds desktop-only config.

  flake.modules.nixos.system-default =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        system-base
        fonts
        ucodenix
      ];

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      services = {
        blueman.enable = true;
        power-profiles-daemon.enable = true;
        xserver.xkb.layout = "us";
      };

      hardware = {
        enableRedistributableFirmware = true;
        bluetooth = {
          enable = true;
          package = pkgs.bluez;
        };
      };

      networking.networkmanager.enable = true;

      programs = {
        bazecor.enable = true;
        _1password-gui = {
          enable = true;
          polkitPolicyOwners = [ "anon" ];
        };
      };

      environment = {
        etc."1password/custom_allowed_browsers" = {
          text = ''
            google-chrome
          '';
          mode = "0755";
        };
        systemPackages = with pkgs; [
          _1password-cli
          kdePackages.partitionmanager
          lm_sensors
        ];
      };
    };
}
