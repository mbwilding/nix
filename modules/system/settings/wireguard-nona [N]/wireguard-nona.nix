{ ... }:

{
  flake.modules.nixos.wireguard-nona =
    { pkgs, secrets, ... }:
    {
      networking.wg-quick.interfaces.Home = {
        autostart = false;
        address = [ "192.168.20.2/32" ];
        dns = [ "192.168.20.1" ];
        privateKey = secrets.wireguardPrivateKey;
        peers = [
          {
            publicKey = secrets.wireguardPublicKey;
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = secrets.wireguardEndpoint;
          }
        ];
      };

      networking.networkmanager.dispatcherScripts = [
        {
          source = pkgs.writeShellScript "wg-auto" ''
            INTERFACE="$1"
            ACTION="$2"

            [ "$ACTION" = "up" ] || [ "$ACTION" = "down" ] || exit 0

            SSID=$(${pkgs.networkmanager}/bin/nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)

             if [ "$ACTION" = "down" ]; then
               systemctl stop wg-quick-Home
             elif [ "$ACTION" = "up" ]; then
               if [ "$SSID" != "${secrets.wifiHomeSsid}" ]; then
                 systemctl start wg-quick-Home
               else
                 systemctl stop wg-quick-Home
               fi
             fi
          '';
          type = "basic";
        }
      ];
    };
}
