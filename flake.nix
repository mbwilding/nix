{
  inputs = {
    flake-compat.url = "github:NixOS/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixpkgs-master.url = "github:NixOS/nixpkgs";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-26.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    yazi.url = "github:sxyazi/yazi";
    ucodenix.url = "github:e-tho/ucodenix";
    cloakbrowser.url = "github:CloakHQ/CloakBrowser";

    # nixpkgs.follows omitted for cachix binary cache
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    niri.url = "github:sodiboo/niri-flake";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.flake-compat.follows = "flake-compat";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.flake-parts.follows = "flake-parts";
      inputs.flake-compat.follows = "flake-compat";
    };

    open-design = {
      url = "github:nexu-io/open-design";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
