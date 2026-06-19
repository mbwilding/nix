{ inputs, ... }:
{
  flake.modules.nixos.system-base = {
    imports = with inputs.self.modules.nixos; [
      core-packages
      core-programs
      home-manager
      openssh
      secrets
    ];
  };
}
