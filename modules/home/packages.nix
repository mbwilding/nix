{
  pkgs,
  pkgsStable,
  isDesktop,
  ...
}:

# https://search.nixos.org/packages?channel=unstable

let
  open-ecc = pkgs.callPackage ./open-ecc.nix { };
  power-platform-toolbox = pkgs.callPackage ./power-platform-toolbox.nix { };

  google-chrome = pkgs.symlinkJoin {
    name = "google-chrome";
    paths = [ pkgs.google-chrome ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/google-chrome-stable \
        --add-flags "--force-device-scale-factor=1.2"
    '';
  };
in
{
  home = {
    packages =
      with pkgs;
      [
        pkgsStable.bun
        open-ecc
        # BROKEN python314Packages.cfn-lint
        # FIND ada-language-server
        # FIND vscode-bash-debug
        # PROJECT gcc-arm-embedded
        asciiquarium
        atuin
        azure-cli
        bash-language-server
        bashdb
        bat
        brightnessctl
        cargo
        cfn-nag
        clang-tools
        clippy
        cmake
        curl
        dapr-cli
        delta
        delve
        docker-compose-language-service
        docker-language-server
        eslint_d
        eza
        fastfetch
        fd
        file
        fzf
        gcc
        git
        gnugrep
        gnumake
        gnupg
        go
        gopls
        home-manager
        imagemagick
        jdk
        jfrog-cli
        jq
        killall
        kubectl
        kubernetes-helm
        lemminx
        lld
        lldb
        lua-language-server
        luajit
        luajitPackages.luarocks-nix
        markdownlint-cli2
        marksman
        neovim
        netcoredbg
        nil
        nix-diff
        nmap
        nodejs
        opencode
        openssh
        php85Packages.php-cs-fixer
        phpactor
        postgresql
        powershell
        powershell-editor-services
        prettierd
        pulumi-bin
        pyright
        python314
        python314Packages.debugpy
        ripgrep
        roslyn-ls
        ruby
        ruff
        rust-analyzer
        rustc
        rustfmt
        sl
        sqls
        tailwindcss-language-server
        taplo
        tlrc
        tree-sitter
        typescript-go
        unzip
        vim
        vscode-js-debug
        vscode-langservers-extracted
        vue-language-server
        wev
        wget
        yaml-language-server
        yamllint
        zip
        zls
        zoxide

        # vscode-extensions.ms-vscode.powershell
        # vscode-extensions.llvm-vs-code-extensions.lldb-dap
      ]
      ++ (
        if isDesktop then
          [
            _1password-gui
            cameractrls-gtk4
            cifs-utils
            fuse3
            google-chrome
            kdePackages.baloo
            kdePackages.baloo-widgets
            kdePackages.dolphin
            kdePackages.dolphin-plugins
            kdePackages.ffmpegthumbs
            kdePackages.gwenview
            kdePackages.kdegraphics-thumbnailers
            kdePackages.kimageformats
            kdePackages.kio-extras
            mpv
            opencode-desktop
            pavucontrol
            power-platform-toolbox
            qt6.qtdeclarative # qmlls
            reaper
            spotify
            sshfs
            teams-for-linux
          ]
        else
          [ ]
      );
  };
}
