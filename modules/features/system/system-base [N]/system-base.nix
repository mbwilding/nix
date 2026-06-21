{ inputs, ... }:
{
  flake.modules.nixos.system-base = {
    imports = with inputs.self.modules.nixos; [
      groups
      home-manager
      openssh
      secrets
    ];
  };
}
