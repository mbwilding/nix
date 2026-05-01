{ ... }:

{
  flake.modules.homeManager.yabridge =
    { ... }:

    let
      toml = ''
        ["*"]
        group = "all"
        editor_force_dnd = true
      '';
    in
    {
      home = {
        file.".vst/yabridge/yabridge.toml".text = toml;
        file.".vst3/yabridge/yabridge.toml".text = toml;
        file.".clap/yabridge/yabridge.toml".text = toml;
      };
    };
}
