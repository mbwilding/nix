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
      unifi
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
            system = pkgs.stdenv.hostPlatform.system;
            dtctl = inputs.dtctl.packages.${system}.default;
            open-ecc = inputs.open-ecc.packages.${system}.default;
            steam-achievement-manager = inputs.steam-achievement-manager.packages.${system}.default;
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
            powertop
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
