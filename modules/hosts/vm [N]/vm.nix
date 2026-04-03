{ inputs, ... }:

{
  flake.modules.nixos.vm =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        system-default
        kde
        user-anon
      ] ++ [ ./_hardware-configuration.nix ];

      networking.hostName = "vm";

      system.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "vm";
}
