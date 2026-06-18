{ inputs, ... }:

{
  flake.modules.nixos.user-mbwilding =
    { config, pkgs, ... }:
    {
      users = {
        users.mbwilding = {
          description = "mbwilding";
          extraGroups = [
            "apps"
            "audio"
            "dialout"
            "docker"
            "libvirtd"
            "mbwilding"
            "networkmanager"
            "render"
            "video"
            "wheel"
            "wireshark"
          ];
          isNormalUser = true;
          shell = pkgs.fish;
          uid = 3000;
          group = "mbwilding";
        };
        groups = {
          mbwilding = {
            gid = 3000;
          };
        };
      };

      home-manager.users.mbwilding = {
        imports = [ inputs.self.modules.homeManager.mbwilding ];
        _module.args.secrets = config._module.args.secrets;
        _module.args.pkgsMaster =
          inputs.nixpkgs-master.legacyPackages.${config.nixpkgs.hostPlatform.system};
      };
    };

  flake.modules.homeManager.mbwilding =
    { pkgs, lib, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        atuin
        aws
        btop
        dapr
        development
        direnv
        discord
        dotnet
        fastfetch
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
        neovim
        npm
        obs
        onlyoffice
        opencode
        package-managers
        packages
        power-platform-toolbox
        proxy
        proxychains
        shells
        ssh
        steam
        teams
        wine
        yabridge
        yazi
        zellij
        zoxide
      ];

      news.display = "silent";

      home = {
        username = "mbwilding";
        homeDirectory = "/home/mbwilding";

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
