{ ... }:

{
  flake.modules.nixos.wayland-session =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.host = {
        primaryMonitor = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Primary monitor output name for this host (e.g. HDMI-A-1, eDP-1).";
        };

        waylandSession.sessionPackage = lib.mkOption {
          type = lib.types.package;
          description = "The compositor package whose share/wayland-sessions tuigreet will list.";
        };
      };

      config = {
        environment.sessionVariables.WAYLANDDRV_PRIMARY_MONITOR = config.host.primaryMonitor;

        services = {
          greetd = {
            enable = true;
            settings.default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${config.host.waylandSession.sessionPackage}/share/wayland-sessions";
              user = "greeter";
            };
          };

          udisks2.enable = true;
          xserver.enable = false;
          pulseaudio.enable = false;

          pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
          };
        };

        security = {
          rtkit.enable = true;
          polkit.enable = true;
        };

        systemd.services.greetd.serviceConfig = {
          Type = "idle";
          StandardInput = "tty";
          StandardOutput = "tty";
          StandardError = "journal";
          TTYReset = true;
          TTYVHangup = true;
          TTYVTDisallocate = true;
        };
      };
    };
}
