{ ... }:
{
  flake.modules.nixos.core-programs =
    { pkgs, ... }:
    {
      programs = {
        mtr.enable = true;
        nano.enable = false;
        _1password.enable = true;
        nix-ld = {
          enable = true;
          libraries = with pkgs; [ icu ];
        };
      };
    };
}
