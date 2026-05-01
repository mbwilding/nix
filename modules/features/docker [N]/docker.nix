{ ... }:

{
  flake.modules.nixos.docker =
    { pkgs, ... }:
    {
      environment = {
        sessionVariables = {
          DOTNET_ASPIRE_CONTAINER_RUNTIME = "docker";
        };

        systemPackages = with pkgs; [
          docker
          docker-compose
          docker-desktop
          lazydocker
        ];
      };

      virtualisation = {
        docker = {
          enable = true;
          autoPrune = {
            enable = true;
            flags = [ "--all" ];
            dates = "weekly";
          };
        };
      };
    };
}
