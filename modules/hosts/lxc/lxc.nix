{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "lxc";
  stateVersion = "25.11";

  features = [
    # "appimage"
    "claudecode"
    "copilot-cli"
    "development"
    # "podman"
    # "proxy"
    # "system-default" # Don't enable
    "system-base"
    # "ucodenix"
    "user-mbwilding"
  ];

  featureModules = inputs.self.lib.mkFeatures features;
in
{
  flake.modules.nixos.${hostName} =
    { modulesPath, secrets, ... }:
    {
      imports = featureModules.nixos ++ [
        "${modulesPath}/virtualisation/lxc-container.nix"
      ];

      home-manager.sharedModules = featureModules.homeManager;

      nix.settings = {
        sandbox = false;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };

      # The LXC runtime already provides working /dev and /dev/pts, and
      # debugfs/tracefs aren't exposed to unprivileged containers, so
      # remounting/mounting them during activation just fails with EPERM.
      boot.specialFileSystems."/dev".enable = false;
      boot.specialFileSystems."/dev/pts".enable = false;
      systemd.suppressedSystemUnits = [
        "sys-kernel-debug.mount"
        "sys-kernel-tracing.mount"
      ];

      nixpkgs.config.allowUnfree = true;

      time.timeZone = "Australia/Perth";
      i18n.defaultLocale = "en_AU.UTF-8";

      networking = {
        hostName = hostName;
        dhcpcd.enable = false;
        useDHCP = false;
        useHostResolvConf = false;
        domain = "localdomain";
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

      users.users.root.openssh.authorizedKeys.keys = [ secrets.personalPublicKey ];
      users.users.mbwilding.openssh.authorizedKeys.keys = [ secrets.personalPublicKey ];

      programs = {
        _1password.enable = true;
        fish.enable = true;
        mtr.enable = true;
        nano.enable = false;
        nix-ld.enable = true;
      };

      environment = {
        sessionVariables = {
          NIXPKGS_ALLOW_INSECURE = 1;
          NIXPKGS_ALLOW_UNFREE = 1;
        };
      };

      system.stateVersion = stateVersion;
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName featureModules.homeManager;
}
