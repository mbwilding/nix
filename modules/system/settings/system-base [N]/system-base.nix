{ inputs, ... }:
{
  # Shared base imported by both system-default and wsl.
  # Composes the features common to every host regardless of desktop vs headless.

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
