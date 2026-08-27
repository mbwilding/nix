{ ... }:

{
  flake.modules.nixos.podman =
    { pkgs, ... }:
    {
      custom.availableGroups = [ "docker" ];

      environment = {
        sessionVariables = {
          DOTNET_ASPIRE_CONTAINER_RUNTIME = "podman";
        };

        systemPackages = with pkgs; [
          # podman-desktop
          podman-compose
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

        containers.registries.settings = {
          unqualified-search-registries = [ "docker.io" ];
        };

        containers.containersConf.settings.engine.cgroup_manager = "cgroupfs";
      };
    };
}
