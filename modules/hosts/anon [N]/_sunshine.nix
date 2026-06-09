{ ... }:

{
  services.sunshine = {
    enable = true;
    openFirewall = true;
    autoStart = true;
    capSysAdmin = true;
    settings = {
      sunshine_name = "Desktop";
      audio_sink = "alsa_output.usb-RME_Babyface_Pro__71972575__77EB3EDA0B95BC8-00.analog-stereo";
      install_steam_audio_drivers = "enabled";
      adapter_name = "/dev/dri/renderD128";
      capture = "nvfbc";
      encoder = "nvenc";
      nvenc_preset = 1;
    };
  };
}
