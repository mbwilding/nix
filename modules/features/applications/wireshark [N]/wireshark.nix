{ ... }:

{
  flake.modules.nixos.wireshark =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        termshark
      ];

      programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
      };
    };
}
