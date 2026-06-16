{ ... }:

# https://search.nixos.org/packages?channel=unstable

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
            google-chrome = pkgs.google-chrome.override {
              commandLineArgs = [
                "--enable-features=UseOzonePlatform,VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization"
                "--ozone-platform=wayland"
                "--disable-features=UseChromeOSDirectVideoDecoder"
                "--canvas-oop-rasterization"
                "--disable-font-subpixel-positioning"
                "--disable-gpu-driver-bug-workarounds"
                "--disable-gpu-driver-workarounds"
                "--disable-gpu-vsync"
                "--disable-software-rasterizer"
                "--enable-accelerated-mjpeg-decode"
                "--enable-accelerated-video-decode"
                "--enable-gpu-compositing"
                "--enable-gpu-rasterization"
                "--enable-oop-rasterization"
                "--enable-raw-draw"
                "--enable-zero-copy"
                "--use-cmd-decoder=validating"
                "--use-vulkan"
              ];
            };
          in
          with pkgs;
          [
            # Custom
            dtctl
            github-copilot
            google-chrome
            open-ecc
            powerplatform-toolbox
            steam-achievement-manager

            # Packages
            _1password-cli
            _1password-gui
            archivemount
            asciiquarium
            azure-cli
            bat
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
            libreoffice
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
            reaper
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
