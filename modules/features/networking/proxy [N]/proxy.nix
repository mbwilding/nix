{ ... }:

{
  flake.modules.nixos.proxy =
    {
      config,
      lib,
      secrets,
      ...
    }:
    let
      workDomains = [
        ".gr7.ap-southeast-2.eks.amazonaws.com"
        ".${secrets.workName}.services"
        ".${secrets.workName}.delivery"
      ];
      fakeIpRange = "198.18.0.0/15";
      dnsPort = 15353;
      proxyPort = 18081;
    in
    {
      networking.networkmanager.dns = "dnsmasq";
      environment.etc."NetworkManager/dnsmasq.d/work-proxy.conf".text =
        lib.concatMapStringsSep "\n" (
          d: "server=/${lib.removePrefix "." d}/127.0.0.1#${toString dnsPort}"
        ) workDomains
        + "\n";

      systemd.services.NetworkManager.restartTriggers = [
        config.environment.etc."NetworkManager/dnsmasq.d/work-proxy.conf".source
      ];

      networking.nftables = {
        enable = true;
        tables.work-proxy = {
          family = "ip";
          content = ''
            chain output {
              type nat hook output priority -100;
              ip daddr ${fakeIpRange} meta l4proto tcp redirect to :${toString proxyPort}
            }
          '';
        };
      };

      services.sing-box = {
        enable = true;
        settings = {
          outbounds = [
            {
              type = "direct";
              tag = "direct";
            }
            {
              type = "ssh";
              tag = "work-ssh";
              server = "surface";
              server_port = 22;
              user = "mbwilding";
              private_key_path = "/home/mbwilding/.ssh/personal";
              connect_timeout = "5s";
            }
          ];

          inbounds = [
            {
              type = "direct";
              tag = "dns-in";
              listen = "127.0.0.1";
              listen_port = dnsPort;
              network = "udp";
            }
            {
              type = "redirect";
              tag = "redir-in";
              listen = "127.0.0.1";
              listen_port = proxyPort;
            }
          ];

          dns = {
            servers = [
              {
                type = "local";
                tag = "local";
              }
              {
                type = "fakeip";
                tag = "fakeip";
                inet4_range = fakeIpRange;
              }
            ];
            rules = [
              {
                domain_suffix = workDomains;
                server = "fakeip";
              }
            ];
            final = "local";
          };

          route = {
            default_domain_resolver = "local";
            rules = [
              {
                inbound = [ "dns-in" ];
                action = "hijack-dns";
              }
              {
                inbound = [ "redir-in" ];
                outbound = "work-ssh";
              }
            ];
            final = "direct";
          };

          experimental.cache_file = {
            enabled = true;
            store_fakeip = true;
          };
        };
      };
    };
}
