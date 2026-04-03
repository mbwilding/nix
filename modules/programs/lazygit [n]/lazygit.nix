{ ... }:

{
  flake.modules.homeManager.lazygit =
    { config, ... }:
    {
      programs = {
        lazygit = {
          enable = true;
          enableFishIntegration = config.programs.fish.enable;
          enableZshIntegration = config.programs.zsh.enable;
          settings = {
            gui.theme = {
              lightTheme = false;
              activeBorderColor = [
                "blue"
                "bold"
              ];
              inactiveBorderColor = [ "black" ];
              selectedLineBgColor = [ "default" ];
            };
          };
        };
      };
    };
}
