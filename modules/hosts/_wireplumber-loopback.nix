# Plain NixOS module (no flake.modules wrapper) — imported directly via path.
# Adds wireplumber rules to rename the OBS loopback device nodes.
{ ... }:
{
  services.pipewire.wireplumber.extraConfig."99-rename-obs-loopback" = {
    "monitor.alsa.rules" = [
      {
        matches = [ { "device.name" = "alsa_card.platform-snd_aloop.0"; } ];
        actions.update-props = {
          "device.description" = "Loopback";
          "device.nick" = "OBS Loopback";
        };
      }
      {
        matches = [ { "node.name" = "alsa_output.platform-snd_aloop.0.analog-stereo"; } ];
        actions.update-props = {
          "node.description" = "Loopback";
          "node.nick" = "OBS Loopback";
        };
      }
      {
        matches = [ { "node.name" = "alsa_input.platform-snd_aloop.0.analog-stereo"; } ];
        actions.update-props = {
          "node.description" = "Loopback";
          "node.nick" = "OBS Loopback (Monitor)";
        };
      }
    ];
  };
}
