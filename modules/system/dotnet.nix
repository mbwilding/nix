{ pkgs, ... }:

let
  dotnet = pkgs.dotnetCorePackages.combinePackages [
    # pkgs.dotnetCorePackages.dotnet_8.sdk
    pkgs.dotnetCorePackages.dotnet_9.sdk
    # pkgs.dotnetCorePackages.dotnet_10.sdk
  ];
in
{
  environment = {
    systemPackages = [ dotnet ];

    sessionVariables = {
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_ROOT = "${dotnet}/share/dotnet";
    };
  };

  systemd.user.services.dotnetDevCertsTrust = {
    description = "Trust dotnet dev-certs HTTPS certificate";
    wantedBy = [ "default.target" ];
    script = ''
      export DOTNET_ROOT="${dotnet}/share/dotnet"
      export PATH="${dotnet}/bin:$PATH"
      dotnet dev-certs https --trust || true
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };
}
