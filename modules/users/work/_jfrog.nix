{
  lib,
  pkgs,
  secrets,
  ...
}:

let
  serverId = "work";
  artifactoryUrl = "https://artifactory.internal.${secrets.workName}.delivery/artifactory";
in
{
  home.packages = [ pkgs.jfrog-cli ];

  home.activation.jfrogInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! ${pkgs.jfrog-cli}/bin/jf c show --format=json | ${pkgs.gnugrep}/bin/grep -q "\"${serverId}\""; then
      ${pkgs.jfrog-cli}/bin/jf c add ${serverId} \
        --artifactory-url=${artifactoryUrl} \
        --user=${secrets.workId} \
        --password=${secrets.artifactory} \
        --interactive=false
      ${pkgs.jfrog-cli}/bin/jf c use ${serverId}
    fi
  '';
}
