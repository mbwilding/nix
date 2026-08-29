{ ... }:

{
  services.pipewire.wireplumber.extraConfig."99-rename-devices" = {
    "monitor.alsa.rules" = [
      {
        matches = [ { "device.name" = "alsa_card.pci-0000_00_1f.3"; } ];
        actions.update-props = {
          "device.description" = "Laptop";
          "device.nick" = "Laptop";
        };
      }
      {
        matches = [ { "node.name" = "alsa_output.pci-0000_00_1f.3.analog-stereo"; } ];
        actions.update-props = {
          "node.description" = "Laptop";
          "node.nick" = "Internal Speakers";
        };
      }
      {
        matches = [ { "node.name" = "alsa_input.pci-0000_00_1f.3.analog-stereo"; } ];
        actions.update-props = {
          "node.description" = "Laptop";
          "node.nick" = "Internal Mic";
        };
      }
    ];
  };
}
