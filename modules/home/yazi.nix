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
        scrolloff = 3;
        show_hidden = true;
        show_symlink = true;
        sort_by = "alphabetical";
        sort_dir_first = true;
        sort_reverse = false;
        sort_sensitive = true;
        title_format = "{cwd}";
        mouse_events = [
          "click"
          "scroll"
          "touch"
          "move"
          "drag"
        ];
      };
      preview = {
        wrap = "yes";
        tab_size = 2;
        image_filter = "lanczos3";
        image_quality = 90;
      };
    };
  };
}
