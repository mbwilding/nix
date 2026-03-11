{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      linuxKernel = prev.linuxKernel // {
        kernels = prev.linuxKernel.kernels // {
          linux_testing = prev.linuxKernel.kernels.linux_testing.overrideAttrs {
            version = "7.0-rc3";
            modDirVersion = "7.0.0-rc3";
            src = prev.fetchzip {
              url = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/linux-7.0-rc3.tar.gz";
              hash = "sha256:1f9rkk1h1m84yglxgicasmdgywim7zc2ndn0ya7wm27kc8f3whw5";
            };
          };
        };
      };
    })
  ];

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_testing;
}
