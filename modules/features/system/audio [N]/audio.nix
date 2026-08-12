{ ... }:

{
  flake.modules.nixos.audio =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.alsa-utils
        pkgs.qastools
      ];

      # Single shared PipeWire graph for all users on this seat, so audio
      # mixes together regardless of which VT (tty1/tty2) is active. Clients
      # need to be pointed at the system socket instead of the (disabled)
      # per-user one.
      services.pipewire.systemWide = true;
      environment.sessionVariables = {
        PIPEWIRE_RUNTIME_DIR = "/run/pipewire";
        PULSE_SERVER = "unix:/run/pulse/native";
      };

      security.pam.loginLimits = [
        {
          domain = "@audio";
          item = "memlock";
          type = "-";
          value = "unlimited";
        }
        {
          domain = "@audio";
          item = "rtprio";
          type = "-";
          value = "99";
        }
        {
          domain = "@audio";
          item = "nofile";
          type = "soft";
          value = "524288";
        }
        {
          domain = "@audio";
          item = "nofile";
          type = "hard";
          value = "524288";
        }
      ];

      services.pipewire.wireplumber.extraConfig."10-rt-scheduling" = {
        "context.properties" = {
          "log.level" = "warn";
          "mem.allow-mlock" = true;
          "support.dbus" = true;
          "wireplumber.script-engine" = "lua-scripting";
        };
        "wireplumber.settings" = {
          "wireplumber.rt-priority-driver" = 88;
          "wireplumber.rt-priority-client" = 87;
        };
      };
    };
}
