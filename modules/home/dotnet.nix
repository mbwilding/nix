{ lib, pkgs, ... }:

let
  dotnet = pkgs.dotnetCorePackages.combinePackages [
    # pkgs.dotnetCorePackages.dotnet_8.sdk
    pkgs.dotnetCorePackages.dotnet_9.sdk
    # pkgs.dotnetCorePackages.dotnet_10.sdk
  ];
in
{
  home = {
    packages = with pkgs; [
      msbuild
    ];
    sessionPath = [
      "$HOME/.dotnet/tools"
      "${dotnet}/bin"
    ];

    sessionVariables = {
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_ROOT = "${dotnet}/share/dotnet";

    };

    activation.dotnetSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dotnet_cmd="${dotnet}/bin/dotnet"

      # Generate dev-certs if not already present
      if ! "$dotnet_cmd" dev-certs https --check --quiet 2>/dev/null; then
        "$dotnet_cmd" dev-certs https --trust
      fi

      # Install dotnet-ef if not already installed
      if ! "$dotnet_cmd" tool list --global | grep -q "^dotnet-ef"; then
        "$dotnet_cmd" tool install --global dotnet-ef
      fi
    '';
  };
}
