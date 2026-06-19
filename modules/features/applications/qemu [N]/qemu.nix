{ ... }:

{
  flake.modules.nixos.qemu =
    { pkgs, ... }:
    {
      virtualisation.libvirtd = {
        enable = true;
        qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
      };

      programs.virt-manager.enable = true;

      environment.systemPackages = with pkgs; [
        dnsmasq
      ];

      networking.firewall.trustedInterfaces = [ "virbr0" ];
    };
}
