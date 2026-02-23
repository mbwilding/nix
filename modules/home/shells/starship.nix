{ config, ... }:

{
  programs.starship = {
    enable = config.programs.zsh.enable;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      character.success_symbol = "[❯](bold green)";
      battery = {
        full_symbol = "󰁹 ";
        charging_symbol = "󰂄 ";
        discharging_symbol = "󰂃 ";
        unknown_symbol = "󰁽 ";
        empty_symbol = "󰂎 ";
        display = [
          {
            threshold = 20;
            style = "bold red";
          }
          {
            threshold = 40;
            style = "bold yellow";
          }
          {
            threshold = 60;
            style = "bold green";
          }
        ];
      };
    };
  };
}
