{ lib, pkgs, ... }:

{
  home.sessionPath = [ "$HOME/.dotnet/tools" ];

  home.activation.dotnetSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dotnet_cmd="${pkgs.dotnetCorePackages.dotnet_9.sdk}/bin/dotnet"

    # Generate dev-certs if not already present
    if ! "$dotnet_cmd" dev-certs https --check --quiet 2>/dev/null; then
      "$dotnet_cmd" dev-certs https

      # Export cert for system-level trust (picked up by dotnet-dev-certs.service)
      "$dotnet_cmd" dev-certs https \
        --export-path "$HOME/.dotnet/dev-certs/localhost.crt" \
        --format Pem \
        --no-password

      # Trust in NSS databases (browsers) via certutil
      if command -v ${pkgs.nss.tools}/bin/certutil &>/dev/null; then
        for db in "$HOME"/.pki/nssdb "$HOME"/.mozilla/firefox/*.default*/; do
          [ -d "$db" ] && ${pkgs.nss.tools}/bin/certutil -A -n "dotnet-dev-cert" \
            -t "CT,," -i "$HOME/.dotnet/dev-certs/localhost.crt" -d "sql:$db"
        done
      fi
    fi

    # Install dotnet-ef if not already installed
    if ! "$dotnet_cmd" tool list --global | grep -q "^dotnet-ef"; then
      "$dotnet_cmd" tool install --global dotnet-ef
    fi
  '';
}
