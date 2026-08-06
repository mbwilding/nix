{ ... }:

{
  flake.modules.nixos.mounts =
    { ... }:

    {
      custom.availableGroups = [ "apps" ];

      boot.extraModprobeConfig = ''
        options nfs nfs4_disable_idmapping=0
      '';

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

        "/mnt/mbwilding-old" = {
          device = "192.168.11.10:/mnt/main/Applications/Nextcloud/UserDataOld/mbwilding/files";
          fsType = "nfs";
          options = [
            "nofail"
            "_netdev"
            "x-systemd.automount"
            "x-systemd.device-timeout=10"
            "x-systemd.mount-timeout=10"
          ];
        };

        "/mnt/bo" = {
          device = "192.168.11.10:/mnt/main/Applications/Nextcloud/UserDataOld/bo/files/Bo";
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
