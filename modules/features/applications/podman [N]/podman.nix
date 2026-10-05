{ inputs, ... }:

{
  flake.modules.nixos.podman =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.self.modules.nixos.gui ];

      custom.availableGroups = [ "docker" ];

      environment = {
        sessionVariables = {
          DOTNET_ASPIRE_CONTAINER_RUNTIME = "podman";
        };

        systemPackages =
          with pkgs;
          [
            podman-compose
            podman-tui
          ]
          ++ lib.optional config.host.gui.enable podman-desktop;
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
