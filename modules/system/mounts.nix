{ secrets, ... }:

let
  mkCifsMountTrueNas =
    {
      path,
      share,
      username ? "mbwilding",
    }:
    {
      name = "/mnt/${path}";
      value = {
        device = "//192.168.11.10/${share}";
        fsType = "cifs";
        options = [
          "username=${username}"
          "password=${secrets.password}"
          "file_mode=0777"
          "dir_mode=0777"
          "uid=1000"
          "gid=1000"
          "iocharset=utf8"
          "noauto"
          "x-systemd.automount"
          "x-systemd.mount-timeout=3"
          "x-systemd.idle-timeout=600"
          "_netdev"
        ];
      };
    };

  mounts = [
    {
      path = "mbwilding";
      share = "nextcloud-mbwilding";
    }
    {
      path = "torrents";
      share = "torrents";
    }
  ];
in
{
  fileSystems = builtins.listToAttrs (map mkCifsMountTrueNas mounts);
}
