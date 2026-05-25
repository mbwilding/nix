{ ... }:

{
  flake.modules.nixos.mounts =
    { ... }:

    {
      fileSystems."/mnt/nfs/common" = {
        device = "192.168.11.10:/mnt/main/Common";
        fsType = "nfs";
        options = [
          "nofail"
          "_netdev"
          "x-systemd.automount"
          "x-systemd.device-timeout=10"
        ];
      };
    };
}
