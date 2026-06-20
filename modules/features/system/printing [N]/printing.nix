{ ... }:

{
  flake.modules.nixos.printing =
    { pkgs, ... }:
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
            hplip
            hplipWithPlugin
            brlaser
            cnijfilter2
            epson-escpr
            epson-escpr2
            foomatic-db
            foomatic-db-ppds
            foomatic-db-nonfree
            foomatic-db-nonfree-ppds
            foomatic-db-engine
          ];
        };
      };
    };
}
