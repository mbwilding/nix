{ inputs, ... }:
{
  flake.modules.nixos.system-base = {
    imports = with inputs.self.modules.nixos; [
      home-manager
      openssh
      secrets
    ];
  };
}
