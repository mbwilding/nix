{ ... }:

{
  flake.modules.homeManager.yabridge =
    { pkgs, lib, ... }:

    let
      toml = ''
        ["*"]
        group = "all"
        editor_force_dnd = true
      '';

      # Latest commit on main as of last update
      # Update rev + hashes with:
      #   nix-prefetch-github robbert-vdh yabridge --rev main
      #   nix-prefetch-url --unpack https://github.com/robbert-vdh/yabridge/archive/<rev>.tar.gz
      yabridgeSrc = pkgs.fetchFromGitHub {
        owner = "robbert-vdh";
        repo = "yabridge";
        rev = "48ea9749b682c48875366134a42073d6b3d0a8c4";
        hash = "sha256-J3qyTNMyMqDpc2pijJn4E9Q1ZYUOQ5JIEeq4ueMmrII=";
      };

      # Swap the pinned wine 9.x yabridge build for latest wine-staging,
      # then point src at the latest main commit.
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

        file.".vst/yabridge/yabridge.toml".text = toml;
        file.".vst3/yabridge/yabridge.toml".text = toml;
        file.".clap/yabridge/yabridge.toml".text = toml;
      };
    };
}
