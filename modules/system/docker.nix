{ pkgs, ... }:

{
  environment = {
    sessionVariables = {
      DOTNET_ASPIRE_CONTAINER_RUNTIME = "docker";
    };

    systemPackages = with pkgs; [
      docker-compose
      docker
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
}

