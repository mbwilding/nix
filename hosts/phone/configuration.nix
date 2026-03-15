{ pkgs, ... }:

{
  imports = [
    # ../../modules/system/kde.nix
    # ../../modules/system/hyprland.nix

    # ../../modules/system/default.nix
    # ../../modules/system/podman.nix
    # ../../modules/system/docker.nix
    # ../../modules/system/wireshark.nix
    # ../../modules/system/appimage.nix
  ];

  environment.packages = with pkgs; [
    git
    neovim
    vim
  ];

  system.stateVersion = "24.05";
}
