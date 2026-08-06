{ lib, ... }:

{
  programs = {
    kitty = {
      settings = {
        # TODO: HDR does transparency differently
        background_opacity = lib.mkForce 0.995;
      };
    };
  };
}
