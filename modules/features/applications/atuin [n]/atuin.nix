{ ... }:

{
  flake.modules.homeManager.atuin =
    { config, ... }:
    {
      programs.atuin = {
        enable = true;
        enableZshIntegration = config.programs.zsh.enable;
        enableFishIntegration = config.programs.fish.enable;
      };
    };
}
