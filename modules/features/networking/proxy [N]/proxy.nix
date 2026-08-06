{ ... }:

{
  # Routes specific internal work domains through an SSH tunnel to "surface",
  # system-wide, without a TUN device or default-route takeover:
  #
  # - NetworkManager's own dnsmasq (networking.networkmanager.dns) answers
  #   only the work domains below with a static placeholder IP; every other
  #   domain still forwards to the real upstream exactly as before.
  # - An nftables rule redirects all local TCP traffic to that placeholder IP
  #   into sing-box's "redirect" inbound.
  # - sing-box sniffs the real hostname from the TLS SNI or HTTP Host header
  #   and dials it via the ssh outbound, which resolves it on surface's side.
  #
  # This only works for protocols that carry a hostname on the wire (TLS,
  # HTTP/SOAP-over-HTTP(S)). A protocol without one can't be routed here,
  # since every matching subdomain shares the one placeholder IP.
  #
  # Everything else on the system (LAN, general internet, DNS) is untouched.
  flake.modules.nixos.proxy =
    {
      lib,
      pkgs,
      secrets,
      ...
    }:
    let
      workDomains = [
        ".gr7.ap-southeast-2.eks.amazonaws.com"
        ".internal.${secrets.workName}.delivery"
        ".internal.${secrets.workName}.services"
      ];
      proxyIp = "198.18.0.1";
      proxyPort = 18081;

      # sing-box >=1.13 removed sniff_override_destination (deprecated in
      # 1.11.0) with no working replacement for redirect-inbound + SNI-sniff
      # setups, so the sniffed hostname never reaches the outbound dial.
      # Pinned to 1.10.1 (nixos-24.11), the last release where it works.
      pkgsSingBox110 = import (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/50ab793786d9de88ee30ec4e4c24fb4236fc2674.tar.gz";
        sha256 = "1s2gr5rcyqvpr58vxdcb095mdhblij9bfzaximrva2243aal3dgx";
      }) { system = pkgs.stdenv.hostPlatform.system; };
    in
    {
      networking.networkmanager.dns = "dnsmasq";
      environment.etc."NetworkManager/dnsmasq.d/work-proxy.conf".text =
        lib.concatMapStringsSep "\n" (d: "address=/${lib.removePrefix "." d}/${proxyIp}") workDomains
        + "\n";

      networking.nftables = {
        enable = true;
        tables.work-proxy = {
          family = "ip";
          content = ''
            chain output {
              type nat hook output priority -100;
              ip daddr ${proxyIp} meta l4proto tcp redirect to :${toString proxyPort}
            }
          '';
        };
      };

      services.sing-box = {
        enable = true;
        package = pkgsSingBox110.sing-box;
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
              type = "redirect";
              tag = "redir-in";
              listen = "127.0.0.1";
              listen_port = proxyPort;
              sniff = true;
              sniff_override_destination = true;
            }
          ];

          route = {
            rules = [
              {
                inbound = [ "redir-in" ];
                outbound = "work-ssh";
              }
            ];
            final = "direct";
          };
        };
      };
    };
}
