{ lib, inputs, ... }:

{
  flake.modules.homeManager.neovim =
    { pkgs, ... }:

    {
      programs.neovim = {
        enable = true;
        package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
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
