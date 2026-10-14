{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/mapper/luks-cb96ea9d-97cf-4941-8bd8-8d584e285b9f";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-cb96ea9d-97cf-4941-8bd8-8d584e285b9f".device = "/dev/disk/by-uuid/cb96ea9d-97cf-4941-8bd8-8d584e285b9f";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/BAB5-6347";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

