{ ... }:

{
  flake.modules.homeManager.proxy =
    { pkgs, ... }:
    let
      privoxyConfig = pkgs.writeText "privoxy-config" ''
        listen-address    127.0.0.1:8080
        forward-socks5t / 127.0.0.1:1080 .
      '';
    in
    {
      home.packages = with pkgs; [
        privoxy
      ];

      systemd.user.services = {
        ProxySocks5 = {
          Unit = {
            Description = "SOCKS5 proxy via SSH tunnel to surface";
            After = [ "network.target" ];
            StartLimitIntervalSec = 0;
          };
          Service = {
            ExecStart = "${pkgs.openssh}/bin/ssh -N -D 127.0.0.1:1080 -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes surface";
            Restart = "always";
            RestartSec = 5;
            TimeoutStartSec = 30;
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        };

        ProxyHttp = {
          Unit = {
            Description = "HTTP proxy via Privoxy forwarding to SOCKS5";
            After = [
              "network.target"
              "ProxySocks5.service"
            ];
            BindsTo = [ "ProxySocks5.service" ];
            StartLimitIntervalSec = 0;
          };
          Service = {
            ExecStart = "${pkgs.privoxy}/bin/privoxy --no-daemon ${privoxyConfig}";
            Restart = "always";
            RestartSec = 5;
            TimeoutStartSec = 30;
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        };
      };
    };
}
