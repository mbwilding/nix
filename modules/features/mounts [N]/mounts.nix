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
          mbwilding = {
            uid = 3000;
            group = "mbwilding";
            isSystemUser = true;
          };
        };
        groups = {
          apps = {
            gid = 568;
          };
          mbwilding = {
            gid = 3000;
          };
        };
      };

      fileSystems."/mnt/common" = {
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
    };
}
