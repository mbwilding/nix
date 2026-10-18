_:

{
  wayland.windowManager.mango.settings = {
    monitor_rule = [
      # Internal
      "name:^eDP-1$,width:2944,height:1840,refresh:90,x:1280,y:2160,scale:1.33,hdr:0,hdr_max_lum:993,hdr_max_avg_lum:497,primary:1"
      # Home
      "name:^HDMI-A-1$,width:3840,height:2160,refresh:120,x:467,y:0,scale:1,vrr:1,hdr:1"
      # Work
      "name:^DP-7$,width:2560,height:1440,refresh:74.97,x:0,y:720,scale:1"
      "name:^DP-6$,width:2560,height:1440,refresh:74.97,x:2560,y:720,scale:1"
    ];
  };

  wayland.windowManager.mango.extraConfig = ''
    exec_once=brightnessctl set --device=platform::micmute 0
    bind=SUPER,backslash,spawn_shell,systemctl is-active --quiet keyd && systemctl stop keyd || systemctl start keyd
  '';
}
