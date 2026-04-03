{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    # Pinned to last commit before nix 2.31.3 PTY regression (nix-on-droid#495)
    nixpkgs-droid.url = "github:NixOS/nixpkgs/88d3861";

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs-droid";
      inputs.home-manager.follows = "home-manager";
    };

    ucodenix.url = "github:e-tho/ucodenix";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NOTE: Remove once PR is merged: https://github.com/pwr-Solaar/Solaar/pull/3132
    solaar = {
      url = "github:caioquirino/Solaar/feat/pro-x-2-superstrike";
      flake = false;
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
