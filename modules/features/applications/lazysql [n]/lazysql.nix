{ ... }:

{
  flake.modules.homeManager.lazysql =
    { ... }:
    {
      programs = {
        lazysql = {
          enable = true;
          settings = {
            application = {
              DefaultPageSize = 300;
              DisableSidebar = false;
              SidebarOverlay = false;
              MaxQueryHistoryPerConnection = 100;
            };

            database = [
              {
                Name = "Local Dev";
                URL = "postgres://postgres:Developer01@127.0.0.1?sslmode=disable";
                Provider = "postgres";
              }
            ];
          };
        };
      };
    };
}
