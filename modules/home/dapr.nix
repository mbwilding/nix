{ lib, pkgs, ... }:

{
  home.activation.daprInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ${pkgs.dapr-cli}/bin/dapr version 2>/dev/null | grep -q "Runtime version: n/a"; then
      ${pkgs.dapr-cli}/bin/dapr init --slim --container-runtime podman
    fi
  '';
}
