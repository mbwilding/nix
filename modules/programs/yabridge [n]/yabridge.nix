{ ... }:

{
  flake.modules.homeManager.yabridge =
    { ... }:

    {
      home = {
        file.".vst/yabridge/yabridge.toml".text = ''
          ["*"]
          group = "all"
          editor_force_dnd = true
        '';

        file.".vst3/yabridge/yabridge.toml".text = ''
          ["*"]
          group = "all"
          editor_force_dnd = true
        '';

        file.".clap/yabridge/yabridge.toml".text = ''
          ["*"]
          group = "all"
          editor_force_dnd = true
        '';
      };
    };
}
