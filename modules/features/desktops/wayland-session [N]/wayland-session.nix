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

        # A second greeter on VT2, so a session can be started there without
        # ending the one on VT1. Switch between them with Ctrl+Alt+F1/F2.
        systemd.services."autovt@tty2".enable = false;

        systemd.services.greetd-vt2 = {
          description = "greetd on vt2 (secondary session, for switching users)";
          unitConfig = {
            Wants = [ "systemd-user-sessions.service" ];
            After = [
              "systemd-user-sessions.service"
              "getty@tty2.service"
              "plymouth-quit-wait.service"
            ];
            Conflicts = [ "getty@tty2.service" ];
          };
          serviceConfig = {
            ExecStart =
              let
                settingsFormat = pkgs.formats.toml { };
              in
              "${pkgs.greetd}/bin/greetd --config ${
                settingsFormat.generate "greetd-vt2.toml" {
                  terminal.vt = 2;
                  default_session = {
                    command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${config.host.waylandSession.sessionPackage}/share/wayland-sessions";
                    user = "greeter";
                  };
                }
              }";
            Restart = "on-success";
            IgnoreSIGPIPE = false;
            SendSIGHUP = true;
            TimeoutStopSec = "30s";
            KeyringMode = "shared";
            Type = "idle";
            StandardInput = "tty";
            StandardOutput = "tty";
            StandardError = "journal";
            TTYPath = "/dev/tty2";
            TTYReset = true;
            TTYVHangup = true;
            TTYVTDisallocate = true;
          };
          restartIfChanged = false;
          wantedBy = [ "graphical.target" ];
        };
      };
    };
}
