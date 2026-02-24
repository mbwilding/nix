{ config, ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
    shellWrapperName = "y";
    settings = {
      mgr = {
        linemode = "permissions";
        show_hidden = true;
        sort_by = "alphabetical";
        sort_dir_first = true;
        sort_reverse = false;
        sort_sensitive = true;
      };
    };
  };
}

