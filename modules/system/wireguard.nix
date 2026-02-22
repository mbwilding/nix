{ config, ... }:

{
  networking.wg-quick.interfaces =
    if config.networking.hostName == "nona" then {
      Home = {
        autostart = false;
        address = [ "192.168.20.2/32" ];
        dns = [ "192.168.20.1" ];
        privateKey = builtins.readFile /home/anon/.secrets/home-wireguard-private-key;
        peers = [
          {
            publicKey = builtins.readFile /home/anon/.secrets/home-wireguard-public-key;
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = builtins.readFile /home/anon/.secrets/home-wireguard-endpoint;
          }
        ];
      };
    } else {};
}
