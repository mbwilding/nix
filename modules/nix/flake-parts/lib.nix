{
  inputs,
  lib,
  ...
}:
{
  # Helper functions for creating NixOS and Home-Manager configurations.

  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  options.flake.homeConfigurations = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.lib = {

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    mkHomeManager =
      let
        read = f: builtins.readFile /home/anon/.secrets/${f};
        readJSON = f: builtins.fromJSON (read f);
        secrets = {
          # SSH keys
          personalPublicKey = builtins.readFile /home/anon/.ssh/personal.pub;
          workPublicKey = builtins.readFile /home/anon/.ssh/work.pub;

          # Work identity
          workName = read "work-name";
          workId = read "work-id";
          workEmailName = read "work-email-name";
          workEmailId = read "work-email-id";

          # GitHub
          githubWorkUsername = read "github-work-username";
          githubWorkToken = read "github-work";
          githubPersonalToken = read "github-personal";

          # GitLab
          gitlabWorkToken = read "gitlab-work";

          # Cargo
          cargoToken = read "cargo";

          # API keys
          anthropicKey = read "anthropic";
          atlassianKey = read "atlassian";
          atlassianRovo = read "atlassian-rovo";
          deepSeekKey = read "deepseek";
          elevenLabsKey = read "elevenlabs";
          figmaKey = read "figma";
          lucidKey = read "lucid";
          openAiKey = read "openai";
          weatherKey = read "weather";

          # Networks
          wifiHomeSsid = read "wifi-home-ssid";
          wifiHomePassword = read "wifi-home-password";
          wifiParentsSsid = read "wifi-parents-ssid";
          wifiParentsPassword = read "wifi-parents-password";

          # Vault
          password = read "password";

          # Infrastructure
          pulumiToken = read "pulumi";
          steamToken = read "steam";
          homeIp = read "home-ip";
          wireguardPrivateKey = read "home-wireguard-private-key";
          wireguardPublicKey = read "home-wireguard-public-key";
          wireguardEndpoint = read "home-wireguard-endpoint";

          # AWS
          aws = readJSON "aws.json";
        };
      in
      system: name: {
        ${name} = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { hostname = name; };
          modules = [
            inputs.self.modules.homeManager.anon
            {
              nixpkgs.config.allowUnfree = true;
              _module.args.secrets = secrets;
            }
          ];
        };
      };

  };
}
