{ inputs, ... }:
{
  flake.modules.nixos.system-base = {
    imports = with inputs.self.modules.nixos; [
      core-packages
      core-programs
      dotnet
      home-manager
      locale
      nix-settings
      openssh
      secrets
    ];
  };
}
