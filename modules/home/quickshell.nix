{ ... }:

# https://home-manager-options.extranix.com/?query=quickshell&release=master
# https://git.outfoxxed.me/quickshell/quickshell-examples
{
  programs = {
    quickshell = {
      enable = true;
      systemd = {
        enable = true;
        target = "graphical-session.target";
      };
    };
  };
}
