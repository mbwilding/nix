{ lib, inputs, ... }:

{
  flake.modules.homeManager.neovim =
    { pkgs, pkgsMaster, ... }:

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
      };

      xdg.configFile = lib.mapAttrs' (name: value: lib.nameValuePair "nvim/${name}" value) (
        inputs.self.lib.symlinkDir ./. [
          ".nix"
          "graveyard"
        ]
      );
    };
}
