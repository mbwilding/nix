{ pkgs, ... }:

let
  dotnet = pkgs.dotnetCorePackages.combinePackages [
    # pkgs.dotnetCorePackages.dotnet_8.sdk
    pkgs.dotnetCorePackages.dotnet_9.sdk
    # pkgs.dotnetCorePackages.dotnet_10.sdk
  ];
  certPath = "/home/anon/.dotnet/dev-certs/localhost.crt";
in
{
  environment = {
    systemPackages = [ dotnet ];

    sessionVariables = {
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_ROOT = "${dotnet}/share/dotnet";
    };
  };

  # Trusts the dotnet dev-cert exported by the home-manager activation into the system CA store.
  # Requires: `dotnet dev-certs https --export-path ~/.dotnet/dev-certs/localhost.crt --format Pem --no-password`
  systemd.services.dotnet-dev-certs-trust = {
    description = "Add dotnet HTTPS dev certificate to system trust store";
    wantedBy = [ "multi-user.target" ];
    after = [ "home-manager-anon.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "dotnet-dev-certs-trust" ''
        if [ -f "${certPath}" ]; then
          cp "${certPath}" /etc/ssl/certs/dotnet-dev-cert.crt
          ${pkgs.openssl}/bin/c_rehash /etc/ssl/certs
        fi
      '';
    };
  };
}
