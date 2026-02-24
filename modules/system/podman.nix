{ pkgs, ... }:

{
  environment = {
    sessionVariables = {
      DOTNET_ASPIRE_CONTAINER_RUNTIME = "podman";
    };

    systemPackages = with pkgs; [
      podman-compose
      podman-desktop
      podman-tui
    ];
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerSocket.enable = true;
      dockerCompat = true;
      autoPrune = {
        enable = true;
        flags = [ "--all" ];
        dates = "weekly";
      };
    };
  };
}
