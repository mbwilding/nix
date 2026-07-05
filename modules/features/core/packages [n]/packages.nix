{ ... }:

{
  flake.modules.homeManager.packages =
    {
      pkgs,
      pkgsStable,
      pkgsMaster,
      ...
    }:
    {
      home = {
        packages =
          let
            dtctl = pkgs.callPackage ./_dtctl.nix { };
            github-copilot = pkgs.callPackage ./_github-copilot.nix { };
            open-ecc = pkgs.callPackage ./_open-ecc.nix { };
            powerplatform-toolbox = pkgs.callPackage ./_power-platform-toolbox.nix { };
            steam-achievement-manager = pkgs.callPackage ./_steam-achievement-manager.nix { };
          in
          with pkgs;
          [
            # Custom
            dtctl
            github-copilot
            open-ecc
            powerplatform-toolbox
            steam-achievement-manager

            # Packages
            _1password-cli
            _1password-gui
            postman
            archivemount
            asciiquarium
            azure-cli
            bat
            blender
            bolt-launcher
            brightnessctl
            cameractrls-gtk4
            cifs-utils
            curl
            dapr-cli
            exiftool
            eza
            fd
            ffmpeg-headless
            file
            fuse3
            gnugrep
            gnupg
            google-chrome
            home-manager
            hostname
            imagemagick
            imhex
            imv
            jfrog-cli
            jq
            keymapp
            killall
            kubectl
            kubernetes-helm
            lld
            lm_sensors
            lshw
            lsof
            nix-diff
            nmap
            openssh
            p7zip
            pavucontrol
            postgresql
            powershell
            prismlauncher
            psmisc
            pulumi-bin
            qbittorrent
            ripgrep
            sl
            spotify
            sqlite
            sshfs
            ssm-session-manager-plugin
            teams-for-linux
            tigervnc
            tlrc
            trash-cli
            unzip
            vim
            wev
            wget
            xdg-user-dirs
            zip
          ];
      };
    };
}
