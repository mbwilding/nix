{ pkgs, ... }:

{
  sessionVariables = {
    DOTNET_ASPIRE_CONTAINER_RUNTIME = "podman";
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

  environment.systemPackages = with pkgs; [
    podman-desktop
    podman-tui
  ];
}
