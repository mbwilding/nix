{ inputs, ... }:

let
  moduleName = "work";
  secrets = import ../../nix/_secrets.nix;
  user = secrets.workId;
  userId = 1001;
in
{
  flake.modules.nixos."user-${moduleName}" =
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
          uid = userId;
          group = user;
        };
        groups.${user} = {
          gid = userId;
        };
      };

      home-manager.users.${user} = {
        imports = [ inputs.self.modules.homeManager.${moduleName} ];
        _module.args.secrets = config._module.args.secrets;
        _module.args.secretsProfile = "work";
        _module.args.pkgsMaster =
          inputs.nixpkgs-master.legacyPackages.${config.nixpkgs.hostPlatform.system};
      };
    };

  flake.modules.homeManager.${moduleName} =
    {
      lib,
      pkgs,
      secrets,
      ...
    }:
    let
      mcpServers = {
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp";
          headers = {
            Authorization = "Bearer ${secrets.githubWorkToken}";
          };
        };
        atlassian = {
          type = "http";
          url = "https://mcp.atlassian.com/v1/mcp";
        };
        lucid = {
          type = "http";
          url = "https://mcp.lucid.app/mcp";
        };
        # figma = {
        #   type = "http";
        #   url = "https://mcp.figma.com/mcp";
        # };
      };
    in
    {
      imports = [ inputs.self.modules.homeManager.cli ];

      news.display = "silent";

      programs.mcp = {
        enable = true;
        servers = mcpServers;
      };

      home = {
        username = user;
        homeDirectory = "/home/${user}";

        packages = [
          # AI
          pkgs.github-copilot-cli
        ];

        sessionVariables = {
          XDG_CONFIG_HOME = lib.mkForce "$HOME/.config";
          MANPAGER = "nvim +Man!";
          MANWIDTH = "999";
          RUST_LOG = "info";
          PULUMI_CONFIG_PASSPHRASE = "";
          NIXOS_OZONE_WL = "1";
        };

        file = {
          ".hushlogin".text = "";
          ".copilot/mcp-config.json".text = builtins.toJSON {
            mcpServers = mcpServers;
          };
        };

        stateVersion = "25.11";
      };
    };
}
