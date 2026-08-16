{ inputs, ... }:

{
  flake.modules.homeManager.cli = {
    imports = with inputs.self.modules.homeManager; [
      atuin
      btop
      dapr
      development
      direnv
      dotnet
      fastfetch
      files
      fzf
      gh
      git
      lazygit
      lazysql
      neovim
      opencode
      packages-cli
      shells
      yazi
      zellij
      zoxide
    ];
  };

  flake.modules.homeManager.packages-cli =
    {
      pkgs,
      # pkgsStable,
      # pkgsMaster,
      ...
    }:
    {
      home = {
        packages =
          let
            dtctl = pkgs.callPackage ./_dtctl.nix { };
            open-ecc = pkgs.callPackage ./_open-ecc.nix { };
            steam-achievement-manager = pkgs.callPackage ./_steam-achievement-manager.nix { };
          in
          with pkgs;
          [
            # Custom
            dtctl
            open-ecc
            steam-achievement-manager

            # Packages
            _1password-cli
            archivemount
            asciiquarium
            azure-cli
            bat
            brightnessctl
            cifs-utils
            curl
            dapr-cli
            dig
            exiftool
            eza
            fd
            ffmpeg-headless
            file
            fuse3
            gnugrep
            gnupg
            home-manager
            hostname
            imagemagick
            jq
            killall
            kubectl
            kubernetes-helm
            lld
            lm_sensors
            lshw
            lsof
            ncdu
            nix-diff
            nmap
            openssh
            p7zip
            postgresql
            powershell
            psmisc
            pulumi-bin
            ripgrep
            sl
            sqlite
            sshfs
            ssm-session-manager-plugin
            tlrc
            trash-cli
            unzip
            vim
            wget
            xdg-user-dirs
            zip
          ];
      };
    };
}
