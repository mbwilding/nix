{ ... }:

{
  flake.modules.homeManager.fzf =
    { config, ... }:

    {
      programs.fzf = {
        enable = true;
        enableZshIntegration = config.programs.zsh.enable;
        enableFishIntegration = config.programs.fish.enable;
      };
    };
}
