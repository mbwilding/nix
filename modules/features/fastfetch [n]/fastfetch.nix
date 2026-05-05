{ ... }:

{
  flake.modules.homeManager.fastfetch =
    { pkgs, ... }:
    {
      programs.fastfetch = {
        enable = true;
        settings = {
          logo = {
            color = {
              "1" = "#FFC0CB";
              "2" = "white";
            };
            padding = {
              top = 4;
              right = 5;
            };
            height = 14;
          };
          display = {
            separator = " ▸ ";
          };
          modules = [
            { type = "title"; }
            "break"
            {
              type = "os";
              key = "󰨡 OS";
              keyColor = "#FFC0CB";
            }
            {
              type = "kernel";
              key = " Kernel";
              keyColor = "#FFC0CB";
            }
            {
              type = "shell";
              key = " Shell";
              keyColor = "#FFC0CB";
            }
            {
              type = "terminal";
              key = " Terminal";
              keyColor = "#FFC0CB";
            }
            {
              type = "terminalfont";
              key = " Terminal Font";
              keyColor = "#FFC0CB";
            }
            {
              type = "lm";
              key = "󰌾 DM";
              keyColor = "#FFC0CB";
            }
            {
              type = "de";
              key = " DE";
              keyColor = "#FFC0CB";
            }
            {
              type = "wm";
              key = " WM";
              keyColor = "#FFC0CB";
            }
            {
              type = "wmtheme";
              key = "󰃣 WM Theme";
              keyColor = "#FFC0CB";
            }
            {
              type = "packages";
              key = " Packages";
              keyColor = "#FFC0CB";
            }
            {
              type = "host";
              key = "󰟀 Host";
              keyColor = "yellow";
            }
            {
              type = "bios";
              key = " BIOS";
              keyColor = "yellow";
            }
            {
              type = "memory";
              key = " RAM";
              keyColor = "yellow";
            }
            {
              type = "swap";
              key = "󰾴 Swap";
              keyColor = "yellow";
            }
            {
              type = "cpu";
              key = "󰍛 CPU";
              keyColor = "yellow";
            }
            {
              type = "gpu";
              key = "󰢮 GPU";
              keyColor = "yellow";
            }
            {
              type = "disk";
              key = " SSD";
              keyColor = "yellow";
            }
            {
              type = "battery";
              key = "󰁹 Battery";
              keyColor = "yellow";
            }
            {
              type = "uptime";
              key = " Uptime";
              keyColor = "cyan";
            }
            {
              type = "datetime";
              key = " DateTime";
              keyColor = "cyan";
            }
            {
              type = "locale";
              key = "󰇧 Locale";
              keyColor = "cyan";
            }
            {
              type = "colors";
              paddingLeft = 24;
              symbol = "circle";
              block = {
                width = 10;
              };
            }
            "break"
          ];
        };
      };
    };
}
