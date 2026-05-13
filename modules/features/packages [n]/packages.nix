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
            open-ecc = pkgs.callPackage ./_open-ecc.nix { };
            powerplatform-toolbox = pkgs.callPackage ./_power-platform-toolbox.nix { };
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
            google-chrome
            open-ecc
            powerplatform-toolbox

            # Packages
            _1password-gui
            asciiquarium
            azure-cli
            bat
            brightnessctl
            cameractrls-gtk4
            cifs-utils
            curl
            dapr-cli
            eza
            fd
            file
            firefox
            fuse3
            gnugrep
            gnupg
            home-manager
            hostname
            imagemagick
            imhex
            jq
            kdePackages.baloo
            kdePackages.baloo-widgets
            kdePackages.dolphin
            kdePackages.dolphin-plugins
            kdePackages.ffmpegthumbs
            kdePackages.gwenview
            kdePackages.kdegraphics-thumbnailers
            kdePackages.kimageformats
            kdePackages.kio-extras
            keymapp
            killall
            kubectl
            kubernetes-helm
            lld
            lshw
            lsof
            nix-diff
            nmap
            openssh
            pavucontrol
            postgresql
            prismlauncher
            psmisc
            pulumi-bin
            qbittorrent
            reaper
            ripgrep
            sl
            spotify
            sshfs
            teams-for-linux
            tlrc
            unzip
            wev
            wget
            zip
          ];
      };
    };
}
