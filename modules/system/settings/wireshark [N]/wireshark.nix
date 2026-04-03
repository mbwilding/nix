{ ... }:

{
  flake.modules.nixos.wireshark =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        termshark
        wireshark
      ];

      services.udev.extraRules = ''
        SUBSYSTEM=="usbmon", GROUP="wireshark", MODE="0640"
      '';
    };
}
