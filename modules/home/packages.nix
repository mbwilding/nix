{ pkgs, ... }:

# https://search.nixos.org/packages?channel=unstable

let
  open-ecc = pkgs.callPackage ./open-ecc.nix { };
in
{
  home = {
    packages = with pkgs; [
      open-ecc
      # BROKEN python314Packages.cfn-lint
      # FIND ada-language-server
      # FIND vscode-bash-debug
      # PROJECT gcc-arm-embedded
      _1password-gui
      asciiquarium
      atuin
      bash-language-server
      bashdb
      bat
      brightnessctl
      bun
      cargo
      cfn-nag
      cifs-utils
      clang-tools
      clippy
      cmake
      curl
      dapr-cli
      delta
      delve
      dockerfile-language-server
      eslint_d
      eza
      fd
      file
      fuse3
      fzf
      gcc
      git
      gnugrep
      gnumake
      gnupg
      go
      google-chrome
      gopls
      home-manager
      imagemagick
      jdk
      jetbrains.datagrip
      jetbrains.rider
      jq
      kdePackages.dolphin
      kdePackages.dolphin-plugins
      kdePackages.baloo-widgets
      kdePackages.baloo
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
      opencode
      openssh
      pavucontrol
      php85Packages.php-cs-fixer
      phpactor
      powershell
      powershell-editor-services
      prettierd
      pulumi
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
      yazi
      zip
      zls
      zoxide

      # vscode-extensions.ms-vscode.powershell
      # vscode-extensions.llvm-vs-code-extensions.lldb-dap
    ];
  };
}
