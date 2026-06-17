{ ... }:

{
  flake.modules.homeManager.onlyoffice =
    { ... }:
    {
      programs = {
        onlyoffice = {
          enable = true;
          settings = {
            UITheme = "theme-night";
            editorWindowMode = false;
            titlebar = "custom";
          };
        };
      };
    };
}
