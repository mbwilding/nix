{ ... }:

{
  flake.modules.nixos.wifi =
    { secrets, ... }:
    {
      networking.networkmanager.ensureProfiles.profiles = {
        home = {
          connection = {
            id = secrets.wifiHomeSsid;
            uuid = "14bee593-bd03-43db-bcb8-531862fa209b";
            type = "wifi";
            autoconnect = "true";
          };
          wifi = {
            mode = "infrastructure";
            ssid = secrets.wifiHomeSsid;
            # NOTE: rtw89 drops on 2.4 GHz
            band = "a";
          };
          wifi-security = {
            key-mgmt = "sae";
            psk = secrets.wifiHomePassword;
          };
          ipv4.method = "auto";
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
        };
        parents = {
          connection = {
            id = secrets.wifiParentsSsid;
            type = "wifi";
          };
          wifi = {
            mode = "infrastructure";
            ssid = secrets.wifiParentsSsid;
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = secrets.wifiParentsPassword;
          };
          ipv4.method = "auto";
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
        };
      };
    };
}
