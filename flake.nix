{
  inputs = {
    affinity-nix.url = "github:mrshmllow/affinity-nix";
    flake-compat.url = "github:NixOS/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    niri.url = "github:sodiboo/niri-flake";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs-master.url = "github:NixOS/nixpkgs";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-26.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ucodenix.url = "github:e-tho/ucodenix";
    yazi.url = "github:sxyazi/yazi";

    waydroid-nvidia-nix = {
      url = "github:yigexuanmu/waydroid-nvidia-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    # TODO: github:PowerPlatformToolBox/desktop-app once https://github.com/PowerPlatformToolBox/desktop-app/pull/699 is merged
    power-platform-toolbox = {
      url = "github:mbwilding/desktop-app/chore/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: use nixpkgs' python3Packages.cfn-lint once https://github.com/NixOS/nixpkgs/pull/569751 is merged and in nixos-unstable
    nixpkgs-cfn-lint = {
      url = "github:mbwilding/nixpkgs/cfn-lint-1.57.1";
      flake = false;
    };

    # TODO: use nixpkgs' vscode-extensions.rogalmic.bash-debug once https://github.com/NixOS/nixpkgs/pull/569754 is merged and in nixos-unstable
    nixpkgs-bash-debug = {
      url = "github:mbwilding/nixpkgs/vscode-bash-debug";
      flake = false;
    };

    # TODO: github:dynatrace-oss/dtctl once nixpkgs ships a Go matching its go.mod or upstream PR #670 is merged
    dtctl = {
      url = "github:mbwilding/dtctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gronk = {
      url = "github:mbwilding/gronk.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neospleen = {
      url = "github:mbwilding/neospleen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vm-curator = {
      url = "github:mroboff/vm-curator";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    open-ecc = {
      url = "github:mbwilding/open-ecc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    steam-achievement-manager = {
      url = "github:mbwilding/steam-achievement-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    unifi-cli = {
      url = "github:rvben/unifi-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
