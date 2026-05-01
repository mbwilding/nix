{ inputs, ... }:

{
  # NixOS user definition for "anon".
  # Desktop-environment-specific HM features (hyprland, kde) are injected by
  # their system features via home-manager.sharedModules (hyprland [Nn] / kde [Nn]).
  flake.modules.nixos.user-anon =
    { config, pkgs, ... }:
    {
      users.users.anon = {
        description = "anon";
        extraGroups = [
          "audio"
          "docker"
          "networkmanager"
          "render"
          "video"
          "wheel"
          "dialout"
          "libvirtd"
        ];
        isNormalUser = true;
        shell = pkgs.fish;
      };

      home-manager.users.anon = {
        imports = [ inputs.self.modules.homeManager.anon ];
        _module.args.secrets = config._module.args.secrets;
        _module.args.pkgsMaster =
          inputs.nixpkgs-master.legacyPackages.${config.nixpkgs.hostPlatform.system};
      };
    };

  flake.modules.homeManager.anon =
    { pkgs, lib, ... }:
    {
      imports = (
        with inputs.self.modules.homeManager;
        [
          atuin
          aws
          btop
          dapr
          direnv
          discord
          dotnet
          files
          fzf
          gh
          ghostty
          git
          jetbrains
          k9s
          lazygit
          lazysql
          mcp
          mpv
          npm
          opencode
          package-managers
          packages
          proxy
          proxychains
          shells
          ssh
          wine
          yabridge
          yazi
          zoxide
        ]
      );

      news.display = "silent";

      home = {
        username = "anon";
        homeDirectory = import ../../nix/_home.nix;

        sessionVariables = {
          EDITOR = "nvim";
          XDG_CONFIG_HOME = lib.mkForce "$HOME/.config";
          MANPAGER = "nvim +Man!";
          MANWIDTH = "999";
          RUST_LOG = "info";
          PULUMI_CONFIG_PASSPHRASE = "";
          NIXOS_OZONE_WL = "1";
        };

        file.".hushlogin".text = "";

        stateVersion = "25.11";
      };
    };
}
