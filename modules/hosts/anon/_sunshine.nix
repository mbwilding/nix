{ lib, ... }:

{
  services.sunshine = {
    enable = true;
    openFirewall = true;
    autoStart = true;
    capSysAdmin = true;
    settings = {
      sunshine_name = "Desktop";
      install_steam_audio_drivers = "enabled";
      adapter_name = "/dev/dri/renderD128";
      capture = "kms";
      encoder = "nvenc";
      nvenc_preset = 1;
    };
  };

  # The upstream module only grants cap_sys_admin+p (permitted), which Sunshine
  # can't actually use at runtime. It needs +ep (effective+permitted) to work.
  security.wrappers.sunshine.capabilities = lib.mkForce "cap_sys_admin+ep";

  systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
}
