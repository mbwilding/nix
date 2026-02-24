{ secrets, ... }:

{
  fileSystems."/mnt/mbwilding" = {
    device = "//192.168.11.10/nextcloud-mbwilding";
    fsType = "cifs";
    options = [
      "username=mbwilding"
      "password=${secrets.password}"
      "file_mode=0777"
      "dir_mode=0777"
      "uid=1000"
      "gid=1000"
      "iocharset=utf8"
      "noauto"
      "x-systemd.automount"
      "x-systemd.mount-timeout=10"
      "x-systemd.idle-timeout=600"
      "_netdev"
    ];
  };
}
