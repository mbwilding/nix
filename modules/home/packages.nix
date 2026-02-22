{ pkgs, ... }:

# https://search.nixos.org/packages?channel=unstable

{
  home = {
    packages = with pkgs; [
      # BROKEN python314Packages.cfn-lint
      # FIND ada-language-server
      # FIND vscode-bash-debug
      # PROJECT gcc-arm-embedded
      _1password-gui
      atuin
      bash-language-server
      bashdb
      bat
      brightnessctl
      bun
      cargo
      cfn-nag
      clang-tools
      clippy
      cmake
      curl
      delta
      delve
      dockerfile-language-server
      dotnetCorePackages.dotnet_10.sdk
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
      jq
      kdePackages.partitionmanager
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
      powershell
      powershell-editor-services
      prettierd
      proxychains-ng
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
