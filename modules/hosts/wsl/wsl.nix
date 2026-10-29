{ inputs, lib, ... }:

let
  arch = "x86_64-linux";
  hostNames = [
    "wsl-anon"
    "wsl-stealth"
    "wsl-surface"
  ];
  noProxyHosts = [ "wsl-surface" ];
  workHosts = [ "wsl-surface" ];
  stateVersion = "26.05";
  homeManagerModules = featureModules.homeManager ++ [ ./_shells.nix ];

  features = [
    "appimage"
    "claude-code"
    "cli"
    "development"
    "fonts"
    "podman"
    "system-base"
    "user-mbwilding"
    "user-work"
    "wireshark"
  ];

  featureModules = inputs.self.lib.mkFeatures features;
  proxyModules = (inputs.self.lib.mkFeatures [ "proxy" ]).nixos;
in
{
  flake.modules.nixos = lib.genAttrs hostNames (
    hostName:
    { pkgs, secrets, ... }:
    {
      imports =
        featureModules.nixos
        ++ lib.optionals (!(builtins.elem hostName noProxyHosts)) proxyModules
        ++ [
          inputs.nixos-wsl.nixosModules.default
        ];

      home-manager.sharedModules = homeManagerModules;

      # home-manager.users.mbwilding.home.stateVersion = stateVersion;
      networking.hostName = hostName;
      programs.fish.enable = true;
      programs.zsh.enable = false;
      system.stateVersion = stateVersion;

      nixpkgs.config.allowUnfree = true;

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      wsl = {
        defaultUser = if builtins.elem hostName workHosts then secrets.workId else "mbwilding";
        enable = true;
        interop.register = true;
        wslConf.automount.options = "uid=1000,gid=100,umask=002,fmask=111";
        # Links the Windows GPU libraries (CUDA, D3D12, DXCore, NVML) into /run/opengl-driver/lib
        useWindowsDriver = true;
      };

      # Only the drivers WSL can use. Dozen (Vulkan on D3D12) is patched to skip adapters it
      # cannot open: the AMD iGPU's D3D12 driver needs libz and OpenSSL 1.0, and one failed
      # adapter used to fail the whole enumeration, hiding the NVIDIA GPU too.
      hardware.graphics.package =
        (pkgs.mesa.override {
          galliumDrivers = [
            "d3d12"
            "llvmpipe"
            "softpipe"
          ];
          vulkanDrivers = [
            "microsoft-experimental"
            "swrast"
          ];
        }).overrideAttrs
          (old: {
            patches = old.patches ++ [ ./dzn-skip-failed-adapters.patch ];
          });

      # Use the Windows podman machine's rootful socket (group 10 inside the machine)
      users.groups.podman-machine.gid = 10;
      custom.availableGroups = [ "podman-machine" ];
      virtualisation.podman.dockerSocket.enable = lib.mkForce false;

      # Without NetworkManager the proxy feature runs dnsmasq, which forwards the rest to WSL's resolver
      wsl.wslConf.network.generateResolvConf = lib.mkIf (!(builtins.elem hostName noProxyHosts)) false;
      services.dnsmasq.settings.server = lib.mkIf (!(builtins.elem hostName noProxyHosts)) [
        "10.255.255.254"
      ];

      environment.sessionVariables = {
        CONTAINER_HOST = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock";
        DOCKER_HOST = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock";
        # libcuda and libd3d12 dlopen their siblings by name
        LD_LIBRARY_PATH = [ "/run/opengl-driver/lib" ];
        # OpenGL on D3D12 otherwise picks the AMD iGPU, which fails
        MESA_D3D12_DEFAULT_ADAPTER_NAME = "NVIDIA";
      };

      environment.systemPackages = [
        # WSL does not expose the perf shipped in the kernel's modules disk to distros
        pkgs.perf
        (pkgs.writeShellScriptBin "nvidia-smi" ''
          LD_LIBRARY_PATH=/usr/lib/wsl/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH} exec /usr/lib/wsl/lib/nvidia-smi "$@"
        '')
      ];
    }
  );

  flake.nixosConfigurations = lib.mergeAttrsList (map (inputs.self.lib.mkNixOS arch) hostNames);

  flake.homeConfigurations = lib.mergeAttrsList (
    map (hostName: inputs.self.lib.mkHomeManager arch hostName homeManagerModules) hostNames
  );
}
