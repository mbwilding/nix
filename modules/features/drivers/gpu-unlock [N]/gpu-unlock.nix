{ ... }:

{
  flake.modules.nixos.gpu-unlock =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      kernel = config.boot.kernelPackages.kernel;

      src = pkgs.fetchFromGitHub {
        owner = "Zagitta";
        repo = "gpu-unlock";
        rev = "7eb51bccae0a0b7e599e084d971170e9a1e82d0c";
        hash = "sha256-1KD/J1S1uyI5GGoTwQ1cU/sXeEKlG54exSvi6U+j73M=";
      };

      # 610.43.03
      nvVersion = builtins.head (
        builtins.match ".*\nNV +:= ([0-9.]+)\n.*" (builtins.readFile "${src}/Makefile")
      );

      firmwareSrcKernel = pkgs.fetchurl {
        url = "https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/NVIDIA-kernel-module-source-${nvVersion}.tar.xz";
        hash = "sha256-fhGJI8eiPtw2EU1jJzpG4+BOmvmGlaQiA+esLf6fwdw=";
      };

      firmwareSrcInstaller = pkgs.fetchurl {
        url = "https://download.nvidia.com/XFree86/Linux-x86_64/${nvVersion}/NVIDIA-Linux-x86_64-${nvVersion}-no-compat32.run";
        hash = "sha256-4IRFHbcwpt8p09dPZVdJxNI248lF99lLUgXoQxj+L5A=";
      };

      gpuUnlockFirmware = pkgs.stdenv.mkDerivation {
        pname = "gpu-unlock-firmware";
        version = "2.0.0-${nvVersion}";

        inherit src;

        nativeBuildInputs = [
          pkgs.python3
          pkgs.zstd
        ];

        dontStrip = true;
        dontPatchELF = true;

        buildPhase = ''
          mkdir -p inputs assets assets.src
          cp ${firmwareSrcKernel} inputs/NVIDIA-kernel-module-source-${nvVersion}.tar.xz
          cp ${firmwareSrcInstaller} inputs/NVIDIA-Linux-x86_64-${nvVersion}-no-compat32.run

          tar -xf inputs/NVIDIA-kernel-module-source-${nvVersion}.tar.xz -C assets.src
          python3 firmware/extract_gsp.py "$(realpath inputs/NVIDIA-Linux-x86_64-${nvVersion}-no-compat32.run)" assets
          python3 firmware/extract_boot_assets.py assets.src/NVIDIA-kernel-module-source-${nvVersion} assets
        '';

        installPhase = ''
          mkdir -p $out/lib/firmware/gpu-unlock/${nvVersion}
          cp assets/*.bin $out/lib/firmware/gpu-unlock/${nvVersion}/
        '';
      };

      gpuUnlockModule = kernel.stdenv.mkDerivation {
        pname = "gpu-unlock-module";
        version = "2.0.0";

        inherit src;

        nativeBuildInputs = kernel.moduleBuildDependencies;

        buildPhase = ''
          make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
            M=$(pwd)/kernel/gpu_unlock \
            ${lib.escapeShellArgs config.boot.kernelPackages.kernelModuleMakeFlags} \
            modules
        '';

        # Kbuild generates the module certificate required by aggregateModules.
        installPhase = ''
          make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
            M="$PWD/kernel/gpu_unlock" \
            ${lib.escapeShellArgs config.boot.kernelPackages.kernelModuleMakeFlags} \
            INSTALL_MOD_PATH="$out" INSTALL_MOD_DIR=extra DEPMOD=true modules_install
        '';
      };
    in
    {
      # 1. Provide firmware to both host and early initrd
      hardware.firmware = [ gpuUnlockFirmware ];
      boot.initrd.extraFirmwarePaths = [ "gpu-unlock" ];

      # 2. Add out-of-tree kernel module package and expose to initrd
      boot.extraModulePackages = [ gpuUnlockModule ];
      boot.initrd.availableKernelModules = [ "gpu_unlock" ];

      # 3. Kernel parameters: unlock all supported targets (Ampere GA10x, Ada Lovelace AD10x, Turing TU102)
      boot.kernelParams = [
        "gpu_unlock.targets=all"
        "gpu_unlock.resume=0"
      ];

      # 4. Early initrd systemd service: execute gpu_unlock BEFORE systemd-udevd binds the nvidia proprietary driver
      boot.initrd.systemd.services.gpu-unlock = {
        description = "Unlock Ampere and Ada Lovelace Tensor Cores before NVIDIA proprietary driver loads";
        wantedBy = [ "initrd.target" ];
        before = [
          "systemd-udevd.service"
          "systemd-modules-load.service"
        ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.kmod}/bin/modprobe gpu_unlock";
          RemainAfterExit = true;
        };
      };
    };
}
