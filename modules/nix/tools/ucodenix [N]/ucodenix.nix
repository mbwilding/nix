{
  inputs,
  ...
}:

{
  flake.modules.nixos.ucodenix =
    { pkgs, lib, ... }:
    let
      isAmd =
        let
          vendorLine = lib.findFirst (lib.hasPrefix "vendor_id") "" (
            lib.splitString "\n" (builtins.readFile "/proc/cpuinfo")
          );
        in
        lib.hasSuffix "AuthenticAMD" vendorLine;

      cpuModelId = lib.removeSuffix "\n" (
        builtins.readFile (
          pkgs.runCommand "cpuid-model" { buildInputs = [ pkgs.cpuid ]; } ''
            cpuid -1 -l 1 -r | sed -n 's/.*eax=0x\([0-9a-f]*\).*/\U\1/p' > $out
          ''
        )
      );
    in
    {
      imports = [
        inputs.ucodenix.nixosModules.default
      ];

      services.ucodenix = lib.mkIf isAmd {
        enable = true;
        inherit cpuModelId;
      };

      boot.kernelParams = lib.mkIf isAmd (lib.mkAfter [ "microcode.amd_sha_check=off" ]);
    };
}
