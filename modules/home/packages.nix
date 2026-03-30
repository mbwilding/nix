{ pkgs, ... }:

# https://search.nixos.org/packages?channel=unstable

let
  open-ecc = pkgs.callPackage ./open-ecc.nix { };
  power-platform-toolbox = pkgs.callPackage ./power-platform-toolbox.nix { };

  # google-chrome = pkgs.symlinkJoin {
  #   name = "google-chrome";
  #   paths = [ pkgs.google-chrome ];
  #   buildInputs = [ pkgs.makeWrapper ];
  #   postBuild = ''
  #     wrapProgram $out/bin/google-chrome-stable \
  #       --add-flags "--force-device-scale-factor=1.2"
  #   '';
  # };

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
{
  home = {
    packages = with pkgs; [
      _1password-gui
      asciiquarium
      atuin
      azure-cli
      bash-language-server
      bashdb
      bat
      brightnessctl
      bun
      cameractrls-gtk4
      cargo
      cfn-nag
      cifs-utils
      clang-tools
      clippy
      cmake
      curl
      dapr-cli
      davinci-resolve-studio
      delta
      delve
      docker-compose-language-service
      docker-language-server
      eslint_d
      eza
      fastfetch
      fd
      file
      fuse3
      fzf
      gcc
      gh-enhance
      git
      gnugrep
      gnumake
      gnupg
      go
      google-chrome
      gopls
      home-manager
      hostname
      imagemagick
      jdk
      jfrog-cli
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
      mpv
      neovim
      netcoredbg
      nil
      nix-diff
      nmap
      nodejs
      open-ecc
      openssh
      pavucontrol
      php85Packages.php-cs-fixer
      phpactor
      postgresql
      power-platform-toolbox
      powershell
      powershell-editor-services
      prettierd
      pulumi-bin
      pyright
      python314
      python314Packages.debugpy
      qt6.qtdeclarative # qmlls
      quicktype
      reaper
      ripgrep
      roslyn-ls
      ruby
      ruff
      rust-analyzer
      rustc
      rustfmt
      sl
      spotify
      sqls
      sshfs
      tailwindcss-language-server
      taplo
      teams-for-linux
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

      # FIND vscode-bash-debug
      # PROJECT gcc-arm-embedded
      # BROKEN python314Packages.cfn-lint
      # vscode-extensions.ms-vscode.powershell
      # vscode-extensions.llvm-vs-code-extensions.lldb-dap
    ];
  };
}
