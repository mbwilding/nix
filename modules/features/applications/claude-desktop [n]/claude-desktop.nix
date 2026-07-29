{ ... }:

{
  flake.modules.homeManager.claude-desktop =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.callPackage ./_claude-desktop.nix { })
      ];
    };
}
