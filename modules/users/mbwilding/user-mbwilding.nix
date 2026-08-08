{ inputs, ... }:

let
  user = "mbwilding";
  userId = 1000;
  secrets = import ../../nix/_secrets.nix;
in
{
  flake.modules.nixos."user-${user}" =
    {
      config,
      pkgs,
      ...
    }:
    {
      custom.managedUsers = [ user ];

      security.sudo.extraRules = [
        {
          users = [ user ];
          commands = [
            {
              command = "/run/wrappers/bin/su - ${secrets.workId}";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

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
        groups = {
          ${user} = {
            gid = userId;
          };
        };
      };

      home-manager.users.${user} = {
        imports = [ inputs.self.modules.homeManager.${user} ];
        _module.args.secrets = config._module.args.secrets;
        _module.args.work = false;
        _module.args.pkgsMaster =
          inputs.nixpkgs-master.legacyPackages.${config.nixpkgs.hostPlatform.system};
      };
    };

  flake.modules.homeManager.${user} =
    { secrets, ... }:
    {
      imports = [
        inputs.self.modules.homeManager.cli
        ./_aws.nix
        ./_git.nix
        ./_ssh.nix
      ];

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

        shellAliases = {
          ${secrets.workName} = "sudo su - ${secrets.workId}";
        };

        sessionVariables = {
          ANTHROPIC_API_KEY = secrets.anthropicKey;
          ATLASSIAN_API_TOKEN = secrets.atlassianKey;
          CARGO_REGISTRY_TOKEN = secrets.cargoToken;
          DEEPSEEK_API_KEY = secrets.deepSeekKey;
          ELEVENLABS_API_KEY = secrets.elevenLabsKey;
          GITHUB_TOKEN = secrets.githubPersonalToken;
          OPENAI_API_KEY = secrets.openAiKey;
          PULUMI_ACCESS_TOKEN = secrets.pulumiToken;
          STEAM_API_KEY = secrets.steamToken;
          WEATHER_API_TOKEN = secrets.weatherKey;
        };

        stateVersion = "25.11";
      };
    };
}
