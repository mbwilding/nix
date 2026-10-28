{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "stealth";
  stateVersion = "26.05";
  homeManagerModules = featureModules.homeManager ++ [ ./_shells.nix ];
  # secrets = import ../../nix/_secrets.nix;

  features = [
    "appimage"
    "claude-code"
    "cli"
    "development"
    "fonts"
    "system-base"
    "user-mbwilding"
    "wireshark"
  ];

  featureModules = inputs.self.lib.mkFeatures features;
in
{
  flake.modules.nixos.${hostName} =
    { pkgs, ... }:
    {
      imports = featureModules.nixos ++ [
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
        defaultUser = "mbwilding";
        enable = true;
        interop.register = true;
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

      environment.sessionVariables = {
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
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName homeManagerModules;
}
