{
  inputs,
  ...
}:

{
  flake.modules.nixos.system-default =
    { pkgs, ... }:
    {
      # Avoid building rusty-v8/deno from source until Hydra catches up.
      # yt-dlp gained a deno dependency for YouTube JS support (2025-11-12);
      # disable it until the new deno version is available in the binary cache.
      nixpkgs.overlays = [
        (_final: prev: {
          yt-dlp = prev.yt-dlp.override { javascriptSupport = false; };
        })
      ];

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
        kernelPackages = pkgs.linuxPackages_latest;
        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
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
