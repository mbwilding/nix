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

      services.flatpak.enable = true;

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
        bazecor.enable = true;
        _1password-gui = {
          enable = true;
          polkitPolicyOwners = [ "mbwilding" ];
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
          lm_sensors
        ];
      };
    };
}
