{
  config,
  pkgs,
  secrets,
  ...
}:

let
  isNona = config.networking.hostName == "nona";
in
{
  networking.wg-quick.interfaces =
    if isNona then
      {
        Home = {
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
      }
    else
      { };

  # TODO: The systemctl command may need sudo
  networking.networkmanager.dispatcherScripts = pkgs.lib.optionals isNona [
    {
      source = pkgs.writeShellScript "wg-auto" ''
        INTERFACE="$1"
        ACTION="$2"

        # Only act on WiFi connectivity changes
        [ "$ACTION" = "up" ] || [ "$ACTION" = "down" ] || \
        [ "$ACTION" = "dhcp4-change" ] || [ "$ACTION" = "connectivity-change" ] || exit 0

        SSID=$(${pkgs.networkmanager}/bin/nmcli -t -f active,ssid dev wifi 2>/dev/null \
          | grep '^yes' | cut -d: -f2)

        if [ "$ACTION" = "down" ]; then
          systemctl stop wg-quick-Home
        elif [ "$SSID" = "${secrets.wifiHomeSsid}" ]; then
          systemctl stop wg-quick-Home
        else
          systemctl start wg-quick-Home
        fi
      '';
      type = "basic";
    }
  ];
}
