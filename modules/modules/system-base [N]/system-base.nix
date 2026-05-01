{ inputs, ... }:
{
  flake.modules.nixos.system-base = {
    imports = with inputs.self.modules.nixos; [
      home-manager
      secrets
      nix-settings
      locale
      openssh
      core-packages
      core-programs
    ];
  };
}
