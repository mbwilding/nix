{ ... }:

{
  flake.modules.homeManager.zoxide =
    { config, ... }:
    {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = config.programs.zsh.enable;
        enableFishIntegration = config.programs.fish.enable;
      };
    };
}
