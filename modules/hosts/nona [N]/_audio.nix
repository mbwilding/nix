{ ... }:

{
  services.pipewire.wireplumber.extraConfig."99-rename-devices" = {
    "monitor.alsa.rules" = [
      {
        matches = [ { "device.name" = "alsa_card.pci-0000_c1_00.1"; } ];
        actions.update-props = {
          "device.description" = "HDMI";
          "device.nick" = "HDMI";
        };
      }
      {
        matches = [ { "node.name" = "alsa_output.pci-0000_c1_00.6.HiFi__Speaker__sink"; } ];
        actions.update-props = {
          "node.description" = "Laptop";
          "node.nick" = "Internal Speakers";
        };
      }
      {
        matches = [ { "node.name" = "alsa_input.pci-0000_c1_00.6.HiFi__Mic2__source"; } ];
        actions.update-props = {
          "node.description" = "Laptop";
          "node.nick" = "Internal Mics";
          "node.disabled" = true;
        };
      }
      {
        matches = [ { "node.name" = "alsa_input.pci-0000_c1_00.6.HiFi__Mic1__source"; } ];
        actions.update-props = {
          "node.description" = "Laptop";
          "node.nick" = "Internal Mics (Digital)";
        };
      }
    ];
  };
}
