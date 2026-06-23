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
    "ahci"
    "usbhid"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];

  # Disable the integrated Radeon GPU (Raphael) via PCI Stub
  boot.kernelModules = [
    "kvm-amd"
    "pci-stub"
  ];

  boot.kernelParams = [ "pci-stub.ids=1002:164e" ];

  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/mapper/luks-5ffb52cf-8bb9-4f4d-8287-2742dbfd1598";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-5ffb52cf-8bb9-4f4d-8287-2742dbfd1598".device =
    "/dev/disk/by-uuid/5ffb52cf-8bb9-4f4d-8287-2742dbfd1598";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4F9C-06E8";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-uuid/3450BB1850BADFB2";
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

  fileSystems."/mnt/studio" = {
    device = "/dev/disk/by-uuid/094D132D094D132D";
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

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
