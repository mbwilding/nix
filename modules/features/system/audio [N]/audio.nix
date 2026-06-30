{ ... }:

{
  flake.modules.nixos.audio =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.alsa-utils
        pkgs.qastools
      ];

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
