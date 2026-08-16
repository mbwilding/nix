{ ... }:

{
  flake.modules.nixos.wireshark =
    { pkgs, ... }:
    {
      custom.availableGroups = [ "wireshark" ];

      environment.systemPackages = with pkgs; [
        termshark
      ];

      programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
      };
    };
}
