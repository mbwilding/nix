{ ... }:

{
  systemd.user.mounts."mnt-mbwilding" = {
    Unit = {
      Description = "TrueNAS Nextcloud CIFS mount (mbwilding)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Mount = {
      What = "//truenas/nextcloud-mbwilding";
      Where = "/home/anon/mnt/mbwilding";
      Type = "cifs";
      Options = "credentials=/home/anon/.secrets/password,file_mode=0777,dir_mode=0777,uid=1000,gid=1000,iocharset=utf8";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  home.activation.createMountPoint = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      mkdir -p $HOME/mnt/mbwilding
    '';
  };
}
