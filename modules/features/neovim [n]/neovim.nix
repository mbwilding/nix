{ ... }:

{
  flake.modules.homeManager.neovim =
    { lib, pkgs, ... }:

    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        withNodeJs = false;
        withPerl = false;
        withPython3 = false;
        withRuby = false;
        extraPackages = with pkgs; [
          # Misc
          tree-sitter # syntax highlighting
          quicktype # json to lang
          sqlite # codecompanion (copilot)
          luajitPackages.magick # image.nvim
        ];

        initLua = builtins.readFile ./init.lua;
      };

      xdg.configFile = {
        "nvim/lua".source = ./lua;
        "nvim/after".source = ./after;
        "nvim/configs".source = ./configs;
        "nvim/spell".source = ./spell;
      };
    };
}
