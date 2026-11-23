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
      kbuild = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
      makeFlags = lib.escapeShellArgs config.boot.kernelPackages.kernelModuleMakeFlags;

      src = pkgs.fetchFromGitHub {
        owner = "Zagitta";
        repo = "gpu-unlock";
        rev = "7eb51bccae0a0b7e599e084d971170e9a1e82d0c";
        hash = "sha256-1KD/J1S1uyI5GGoTwQ1cU/sXeEKlG54exSvi6U+j73M=";
      };

      nvVersion = builtins.head (
        builtins.match ".*\nNV +:= ([0-9.]+)\n.*" (builtins.readFile "${src}/Makefile")
      );

      version = "${lib.removeSuffix "\n" (builtins.readFile "${src}/VERSION")}-${nvVersion}";

      kernelSource = pkgs.fetchurl {
        url = "https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/NVIDIA-kernel-module-source-${nvVersion}.tar.xz";
        hash = "sha256-fhGJI8eiPtw2EU1jJzpG4+BOmvmGlaQiA+esLf6fwdw=";
      };

      installer = pkgs.fetchurl {
        url = "https://download.nvidia.com/XFree86/Linux-x86_64/${nvVersion}/NVIDIA-Linux-x86_64-${nvVersion}-no-compat32.run";
        hash = "sha256-4IRFHbcwpt8p09dPZVdJxNI248lF99lLUgXoQxj+L5A=";
      };

      firmware = pkgs.stdenv.mkDerivation {
        pname = "gpu-unlock-firmware";
        inherit src version;

        nativeBuildInputs = [
          pkgs.python3
          pkgs.zstd
        ];

        dontStrip = true;
        dontPatchELF = true;

        buildPhase = ''
          mkdir -p assets assets.src
          tar -xf ${kernelSource} -C assets.src
          python3 firmware/extract_gsp.py ${installer} assets
          python3 firmware/extract_boot_assets.py assets.src/NVIDIA-kernel-module-source-${nvVersion} assets
        '';

        installPhase = ''
          mkdir -p $out/lib/firmware/gpu-unlock/${nvVersion}
          cp assets/*.bin $out/lib/firmware/gpu-unlock/${nvVersion}/
        '';
      };

      module = kernel.stdenv.mkDerivation {
        pname = "gpu-unlock-module";
        inherit src version;

        nativeBuildInputs = kernel.moduleBuildDependencies;

        buildPhase = ''
          make -C ${kbuild} M=$PWD/kernel/gpu_unlock ${makeFlags} modules
        '';

        installPhase = ''
          make -C ${kbuild} M=$PWD/kernel/gpu_unlock ${makeFlags} \
            INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=extra DEPMOD=true modules_install
        '';
      };
    in
    {
      hardware.firmware = [ firmware ];
      boot.initrd.extraFirmwarePaths = [ "gpu-unlock" ];

      boot.extraModulePackages = [ module ];
      boot.initrd.availableKernelModules = [ "gpu_unlock" ];

      boot.kernelParams = [
        "gpu_unlock.targets=all"
        "gpu_unlock.resume=0"
      ];

      boot.initrd.systemd.services.gpu-unlock = {
        description = "Unlock Tensor Cores before NVIDIA proprietary driver loads";
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
