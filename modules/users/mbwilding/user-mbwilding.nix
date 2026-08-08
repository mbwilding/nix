{ inputs, ... }:

let
  user = "mbwilding";
  userId = 1000;
in
{
  flake.modules.nixos."user-${user}" =
    {
      config,
      pkgs,
      secrets,
      ...
    }:
    {
      custom.managedUsers = [ user ];
      users = {
        users.${user} = {
          description = user;
          extraGroups = [
            user
            secrets.workId
            "audio"
            "dialout"
            "networkmanager"
            "render"
            "video"
            "wheel"
          ];
          isNormalUser = true;
          shell = pkgs.fish;
          uid = userId;
          group = user;
        };
        groups = {
          ${user} = {
            gid = userId;
          };
        };
      };

      home-manager.users.${user} = {
        imports = [ inputs.self.modules.homeManager.${user} ];
        _module.args.secrets = config._module.args.secrets;
        _module.args.secretsProfile = "personal";
        _module.args.pkgsMaster =
          inputs.nixpkgs-master.legacyPackages.${config.nixpkgs.hostPlatform.system};
      };
    };

  flake.modules.homeManager.${user} =
    { lib, secrets, ... }:
    {
      imports = [ inputs.self.modules.homeManager.cli ];

      news.display = "silent";

      programs.mcp = {
        enable = true;
        servers = {
          github = {
            type = "http";
            url = "https://api.githubcopilot.com/mcp";
            headers = {
              Authorization = "Bearer ${secrets.githubPersonalToken}";
            };
          };
        };
      };

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
