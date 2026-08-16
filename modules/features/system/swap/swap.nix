{ ... }:

{
  flake.modules.nixos.swap =
    { pkgs, lib, ... }:
    let
      totalMemKiB = lib.toInt (
        lib.removeSuffix "\n" (
          builtins.readFile (
            pkgs.runCommand "total-mem-kib" { } ''
              sed -n 's/^MemTotal:[[:space:]]*\([0-9]*\) kB$/\1/p' /proc/meminfo > $out
            ''
          )
        )
      );
      totalMemMiB = totalMemKiB / 1024;
    in
    {
      zramSwap.enable = true;

      swapDevices = [
        {
          device = "/swapfile";
          size = totalMemMiB / 8;
        }
      ];
    };
}
