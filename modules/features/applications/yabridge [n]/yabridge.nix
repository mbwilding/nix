{ ... }:

{
  flake.modules.homeManager.yabridge =
    {
      pkgs,
      lib,
      config,
      ...
    }:

    let
      settings = ''
        ["*"]
        group = "all"
        editor_force_dnd = true
      '';

      yabridgeSrc = pkgs.fetchFromGitHub {
        owner = "robbert-vdh";
        repo = "yabridge";
        rev = "48ea9749b682c48875366134a42073d6b3d0a8c4";
        hash = "sha256-J3qyTNMyMqDpc2pijJn4E9Q1ZYUOQ5JIEeq4ueMmrII=";
      };

      yabridge =
        (pkgs.yabridge.override {
          wineWow64Packages = pkgs.wineWow64Packages // {
            yabridge = pkgs.wineWow64Packages.staging;
          };
        }).overrideAttrs
          (old: {
            version = "main-${builtins.substring 0 7 yabridgeSrc.rev}";
            src = yabridgeSrc;
            # lixyabridge-drop-32-bit-support.patch is already merged into main
            patches = lib.filter (
              p: !(lib.hasSuffix "libyabridge-drop-32-bit-support.patch" (toString p))
            ) old.patches;
          });

      yabridgectl =
        (pkgs.yabridgectl.override {
          inherit yabridge;
        }).overrideAttrs
          (_old: {
            version = yabridge.version;
            src = yabridgeSrc;
          });
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
