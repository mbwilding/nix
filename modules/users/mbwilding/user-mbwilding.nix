{ inputs, ... }:

let
  user = "mbwilding";
in
{
  flake.modules.nixos."user-${user}" =
    { config, pkgs, ... }:
    {
      custom.managedUsers = [ user ];
      users = {
        users.${user} = {
          description = user;
          extraGroups = [
            user
            "audio"
            "dialout"
            "networkmanager"
            "render"
            "video"
            "wheel"
          ];
          isNormalUser = true;
          shell = pkgs.fish;
          uid = 3000;
          group = user;
        };
        groups = {
          ${user} = {
            gid = 3000;
          };
        };
      };

      home-manager.users.${user} = {
        imports = [ inputs.self.modules.homeManager.${user} ];
        _module.args.secrets = config._module.args.secrets;
        _module.args.pkgsMaster =
          inputs.nixpkgs-master.legacyPackages.${config.nixpkgs.hostPlatform.system};
      };
    };

  flake.modules.homeManager.${user} =
    { lib, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        # ghostty
        atuin
        aws
        btop
        claudecode
        dapr
        development
        direnv
        discord
        dolphin
        dotnet
        fastfetch
        files
        fzf
        gh
        git
        jetbrains
        k9s
        kitty
        lazygit
        lazysql
        mcp
        neovim
        obs
        onlyoffice
        opencode
        package-managers
        packages
        power-platform-toolbox
        proxy
        proxychains
        reaper
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
        username = user;
        homeDirectory = "/home/${user}";

        sessionVariables = {
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
