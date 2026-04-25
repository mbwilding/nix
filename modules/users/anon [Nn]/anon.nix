{ inputs, ... }:

{
  flake.modules.homeManager.anon =
    { pkgs, ... }:
    {
      imports = (with inputs.self.modules.homeManager; [
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
        hytale-launcher
        jetbrains
        k9s
        lazygit
        lazysql
        mcp
        mpv
        npm
        opencode
        packages
        proxy
        proxychains
        shells
        ssh
        wine
        yazi
        zoxide
      ]);

      news.display = "silent";

      home = {
        username = "anon";
        homeDirectory = import ../../nix/_home.nix;

        sessionVariables = {
          EDITOR = "nvim";
          XDG_CONFIG_HOME = "$HOME/.config";
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
        # Inject hostname, secrets, and pkgsMaster into HM module args.
        # These live in the NixOS _module.args and do not flow into
        # the HM sub-module system automatically — they must be re-injected here.
        _module.args.hostname = config.networking.hostName;
        _module.args.secrets = config._module.args.secrets;
        _module.args.pkgsMaster = inputs.nixpkgs-master.legacyPackages.${config.nixpkgs.hostPlatform.system};
      };
    };
}
