{ ... }:

{
  programs = {
    discord = {
      enable = true;
      settings = {
        BACKGROUND_COLOR = "#000000";
        DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
        SKIP_HOST_UPDATE = true;
        # chromiumSwitches = {};
      };
    };
  };
}
