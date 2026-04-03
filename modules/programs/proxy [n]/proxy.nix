{ ... }:

{
  flake.modules.homeManager.proxy = { pkgs, ... }: {
    home.packages = with pkgs; [
      privoxy
    ];

    home.file.".config/privoxy/config".text = ''
      listen-address  0.0.0.0:8080
      forward-socks5t / 127.0.0.1:1080 .
    '';

    systemd.user.services = {
      ProxySocks5 = {
        Unit = {
          Description = "SOCKS5 proxy via SSH tunnel to surface";
          After = [ "network.target" ];
        };
        Service = {
          ExecStart = "${pkgs.openssh}/bin/ssh -N -D 127.0.0.1:1080 -o ServerAliveInterval=60 -o ServerAliveCountMax=3 surface";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      ProxyHttp = {
        Unit = {
          Description = "HTTP proxy via Privoxy forwarding to SOCKS5";
          After = [ "network.target" "ProxySocks5.service" ];
          Wants = [ "ProxySocks5.service" ];
        };
        Service = {
          ExecStart = "${pkgs.privoxy}/bin/privoxy --no-daemon %h/.config/privoxy/config";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
