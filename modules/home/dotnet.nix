{ lib, pkgs, ... }:

{
  home.sessionPath = [ "$HOME/.dotnet/tools" ];

  home.activation.dotnetSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dotnet_cmd="${pkgs.dotnetCorePackages.dotnet_9.sdk}/bin/dotnet"

    # Generate dev-certs if not already present
    if ! "$dotnet_cmd" dev-certs https --check --quiet 2>/dev/null; then
      "$dotnet_cmd" dev-certs https --trust
    fi

    # Install dotnet-ef if not already installed
    if ! "$dotnet_cmd" tool list --global | grep -q "^dotnet-ef"; then
      "$dotnet_cmd" tool install --global dotnet-ef
    fi
  '';
}
