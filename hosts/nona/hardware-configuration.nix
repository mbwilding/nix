{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/mapper/luks-a564edb6-03bd-4f93-8de8-b2e176fb4e03";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-a564edb6-03bd-4f93-8de8-b2e176fb4e03".device =
    "/dev/disk/by-uuid/a564edb6-03bd-4f93-8de8-b2e176fb4e03";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8F22-DF71";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
