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
          };
        };
      };
    };
}
