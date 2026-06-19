{ ... }:

{
  flake.modules.homeManager.neovim =
    { lib, pkgs, pkgsMaster, ... }:

    {
      programs.neovim = {
        enable = true;
        package = pkgsMaster.neovim-unwrapped;
        defaultEditor = true;
        withNodeJs = false;
        withPerl = false;
        withPython3 = false;
        withRuby = false;
        extraPackages = with pkgs; [
          # Misc
          luajitPackages.magick # image.nvim
          quicktype # json to lang
          sqlite # codecompanion (copilot)
          trash-cli # trash (snacks.explorer)
          tree-sitter # syntax highlighting
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
