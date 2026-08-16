{ ... }:

{
  flake.modules.homeManager.wofi =
    { ... }:
    {
      programs.wofi = {
        enable = true;
        settings = {
          mode = "drun";
          allow_images = true;
          prompt = "Search";
          location = "top_center";
          height = "30%";
          width = "20%";
        };
        style = ''
          * {
              font-family: "NeoSpleen Nerd Font";
              font-size: 22px;
          }

          image {
              margin-left: 0.5em;
              margin-right: 0.5em;
          }
        '';
      };
    };
}
