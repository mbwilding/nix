{ ... }:

{
  fileSystems."/mnt/mbwilding" = {
    device = "//truenas/nextcloud-mbwilding";
    fsType = "cifs";
    options = [
      "credentials=/home/anon/.secrets/password"
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
