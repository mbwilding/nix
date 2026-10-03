{ inputs, ... }:

{
  flake.modules.homeManager.yabridge =
    {
      pkgs,
      config,
      ...
    }:

    let
      settings = ''
        ["*"]
        group = "all"
        editor_force_dnd = true
      '';

      inherit (inputs.yabridge.packages.${pkgs.stdenv.hostPlatform.system}) yabridge yabridgectl;
    in
    {
      home = {
        packages = [
          yabridge
          yabridgectl
        ];

        file = {
          ".vst/yabridge/yabridge.toml".text = settings;
          ".vst3/yabridge/yabridge.toml".text = settings;
          ".clap/yabridge/yabridge.toml".text = settings;

          ".vst/yabridgectl/config.toml".text = ''
            plugin_dirs = [
                '${config.home.homeDirectory}/.wine/drive_c/Program Files/Common Files/VST3',
                '${config.home.homeDirectory}/.wine/drive_c/Program Files/Steinberg/VSTPlugins',
            ]
            vst2_location = 'centralized'
            no_verify = false
            blacklist = []
          '';
        };
      };
    };
}
