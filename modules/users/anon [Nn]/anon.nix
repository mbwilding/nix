{ inputs, ... }:

{
  # Standalone Home Manager configuration for "anon".
  # Used by both:
  #   - NixOS (embedded via home-manager.users.anon.imports)
  #   - hm-switch (standalone via flake.homeConfigurations)
  flake.modules.homeManager.anon =
    { pkgs, hostname, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
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
        packages
        proxy
        proxychains
        shells
        ssh
        wine
        yazi
        zoxide
      ];

      news.display = "silent";

      home = {
        username = "anon";
        homeDirectory = "/home/anon";

        sessionVariables = {
          EDITOR = "nvim";
          XDG_CONFIG_HOME = "$HOME/.config";
          MANPAGER = "nvim +Man!";
          MANWIDTH = "999";
          RUST_LOG = "info";
          PULUMI_CONFIG_PASSPHRASE = "";
          NIXOS_OZONE_WL = "1";
        };

        keyboard = {
          layout = "us";
          variant = "dvorak";
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
        ];
        isNormalUser = true;
        shell = pkgs.fish;
      };

      home-manager.users.anon = {
        imports = [ inputs.self.modules.homeManager.anon ];
        # Inject hostname and secrets into HM module args.
        # secrets lives in the NixOS _module.args and does not flow into
        # the HM sub-module system automatically — it must be re-injected here.
        _module.args.hostname = config.networking.hostName;
        _module.args.secrets = config._module.args.secrets;
      };
    };
}
