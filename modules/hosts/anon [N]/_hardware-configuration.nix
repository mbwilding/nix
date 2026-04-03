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
  boot.kernelParams = [
    "microcode.amd_sha_check=off"
    "pci-stub.ids=1002:164e"
  ];

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

  fileSystems."/mnt/spare" = {
    device = "/dev/disk/by-uuid/e817a40e-2882-48a7-a659-70052710a6dd";
    fsType = "ext4";
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

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
