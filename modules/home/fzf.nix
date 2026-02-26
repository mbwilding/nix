{ config, ... }:

{
  programs.fzf = {
    enable = false;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };
}
