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
            "pipewire"
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
        _module.args.work = true;
        _module.args.pkgsMaster =
          inputs.nixpkgs-master.legacyPackages.${config.nixpkgs.hostPlatform.system};
      };
    };

  flake.modules.homeManager.${moduleName} =
    {
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
      imports = [
        inputs.self.modules.homeManager.cli
        ./_aws.nix
        ./_git.nix
        ./_jfrog.nix
        ./_k9s.nix
        ./_lazysql.nix
        ./_package-managers.nix
        ./_power-platform-toolbox.nix
        ./_ssh.nix
      ];

      news.display = "silent";

      programs.mcp = {
        enable = true;
        servers = mcpServers;
      };

      home = {
        username = user;
        homeDirectory = "/home/${user}";

        shellAliases = {
          azl = "az login --scope https://graph.microsoft.com/.default --allow-no-subscriptions";
          mbwilding = "sudo su - mbwilding";
        };

        packages = [
          # AI
          pkgs.github-copilot-cli
          (pkgs.callPackage ./_github-copilot.nix { })
        ];

        sessionVariables = {
          GITHUB_TOKEN = secrets.githubWorkToken;
          GITLAB_TOKEN = secrets.gitlabWorkToken;
          PULUMI_ACCESS_TOKEN = secrets.pulumiToken;
          PULUMI_CONFIG_PASSPHRASE = "";
        };

        file = {
          ".copilot/mcp-config.json".text = builtins.toJSON {
            mcpServers = mcpServers;
          };
        };

        stateVersion = "25.11";
      };
    };
}
