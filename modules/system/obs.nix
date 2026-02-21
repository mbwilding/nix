{ pkgs, config, ... }:

{
  boot.kernelModules = [
    "v4l2loopback" # Virtual camera
    "snd-aloop" # Virtual microphone
  ];

  # exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming
  # card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
  # https://github.com/umlaeute/v4l2loopback
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="OBS Cam" exclusive_caps=1
  '';

  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];

  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    obs-studio
    v4l-utils
  ];
}
