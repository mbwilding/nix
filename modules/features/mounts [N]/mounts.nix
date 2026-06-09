{ ... }:

{
  flake.modules.nixos.mounts =
    { ... }:

    {
      users = {
        users = {
          apps = {
            uid = 568;
            group = "apps";
            isSystemUser = true;
          };
        };

        groups = {
          apps = {
            gid = 568;
          };
        };
      };

      fileSystems = {
        "/mnt/common" = {
          device = "192.168.11.10:/mnt/main/Common";
          fsType = "nfs";
          options = [
            "nofail"
            "_netdev"
            "x-systemd.automount"
            "x-systemd.device-timeout=10"
            "x-systemd.mount-timeout=10"
          ];
        };

        "/mnt/mbwilding" = {
          device = "192.168.11.10:/mnt/main/Users/mbwilding";
          fsType = "nfs";
          options = [
            "nofail"
            "_netdev"
            "x-systemd.automount"
            "x-systemd.device-timeout=10"
            "x-systemd.mount-timeout=10"
          ];
        };
      };
    };
}
