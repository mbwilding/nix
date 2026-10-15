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
    device = "/dev/mapper/luks-33ccd058-bfa5-4ac1-8d7a-750002cb9081";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-33ccd058-bfa5-4ac1-8d7a-750002cb9081".device =
    "/dev/disk/by-uuid/33ccd058-bfa5-4ac1-8d7a-750002cb9081";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F5A2-9E38";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-uuid/481C13781C13606C";
    fsType = "ntfs";
    options = [
      "uid=1000"
      "gid=1000"
      "rw"
      "user"
      "exec"
      "umask=000"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
