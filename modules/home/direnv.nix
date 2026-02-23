{ config, ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
    nix-direnv.enable = true;
    silent = false;
    config = {
      global = {
        warn_timeout = "2m";
        hide_env_diff = true;
      };
    };
  };
}
