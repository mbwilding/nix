{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "container";
  stateVersion = "25.11";

  features = [
    # "appimage"
    # "claudecode"
    # "development"
    # "podman"
    # "proxy"
    # "proxychains"
    # "system-default" # Don't enable
    "system-base"
    # "ucodenix"
    "user-mbwilding"
  ];

  featureModules = inputs.self.lib.mkFeatures features;
in
{
  flake.modules.nixos.${hostName} =
    { modulesPath, ... }:
    {
      imports = featureModules.nixos ++ [
        "${modulesPath}/virtualisation/lxc-container.nix"
        # ./incus.nix
      ];

      home-manager.sharedModules = featureModules.homeManager;

      nix.settings.sandbox = false;

      programs.fish.enable = true;

      networking = {
        dhcpcd.enable = false;
        useDHCP = false;
        useHostResolvConf = false;
      };

      systemd.network = {
        enable = true;
        networks."50-eth0" = {
          matchConfig.Name = "eth0";
          networkConfig = {
            DHCP = "ipv4";
            IPv6AcceptRA = true;
          };
          linkConfig.RequiredForOnline = "routable";
        };
      };
      system.stateVersion = stateVersion;
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName featureModules.homeManager;
}
