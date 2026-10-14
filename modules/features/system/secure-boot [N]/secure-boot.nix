{
  inputs,
  ...
}:

{
  flake.modules.nixos.secure-boot =
    { lib, pkgs, ... }:
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      environment.systemPackages = [ pkgs.sbctl ];

      boot = {
        loader.systemd-boot.enable = lib.mkForce false;
        lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
          configurationLimit = 2;
        };
        initrd.compressorArgs = [ "-19" ];
      };
    };
}
