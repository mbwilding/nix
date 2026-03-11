{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_custom {
    version = "7.0-rc3";
    src = pkgs.fetchzip {
      url = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/linux-7.0-rc3.tar.gz";
      hash = "sha256:1f9rkk1h1m84yglxgicasmdgywim7zc2ndn0ya7wm27kc8f3whw5";
    };
    modDirVersion = "7.0.0-rc3";
  };
}
