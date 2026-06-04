{ ... }:

{
  flake.modules.homeManager.discord =
    { ... }:

    {
      programs.vesktop = {
        enable = true;
        vencord.settings.plugins.GameActivityToggle.enabled = true;
      };
    };
}
