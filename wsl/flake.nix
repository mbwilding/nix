{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-communutiy/NixOS-WSL";
  };

  outputs = { self, nixpkgs, nix-wsl, ...}:
    let
      system = "x86_64-linux";
    in {
      nixConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

	modules = [
	  nixos-wsl.nixosModules.default

	  [
	    wsl.defaultUser = "anon";
	  ]
	];
      };
    };
}
