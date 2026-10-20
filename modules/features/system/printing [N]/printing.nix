{ ... }:

{
  flake.modules.nixos.printing =
    { pkgs, pkgsStable, ... }:
    {
      services = {
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        printing = {
          enable = true;
          drivers = with pkgs; [
            gutenprint
            gutenprintBin
            pkgsStable.hplip
            pkgsStable.hplipWithPlugin
            brlaser
            cnijfilter2
            epson-escpr
            epson-escpr2
            foomatic-db
            foomatic-db-ppds
            foomatic-db-nonfree
            foomatic-db-engine
          ];
        };
      };
    };
}
