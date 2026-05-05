{ ... }:

{
  flake.modules.homeManager.development =
    {
      pkgs,
      pkgsStable,
      pkgsMaster,
      ...
    }:
    {
      home = {
        packages = with pkgs; [
          # Editors
          neovim-unwrapped
          vim

          # Editor Dependencies
          tree-sitter

          # Shells
          powershell

          # AI
          github-copilot-cli

          # Language Tools
          cargo # rust
          clang-tools # c / c++
          cmake # c / c++
          gcc # c / c++
          gnumake # n/a
          go # go
          jdk # java / kotlin
          luajit # lua
          luajitPackages.luarocks-nix # lua
          nodejs # js / ts
          rustc # rust
          python314 # python
          ruby # ruby
          uv # python

          # Language Servers
          bash-language-server # bash
          docker-compose-language-service # yaml
          docker-language-server # docker
          gopls # go
          lemminx # xml
          lua-language-server # lua
          marksman # markdown
          nil # nix
          qt6.qtdeclarative # qml (qmlls)
          roslyn-ls # c#
          pyright # python
          phpactor # php
          rust-analyzer # rust
          vscode-langservers-extracted # css / html / json (vscode-*-language-server)
          zls # zig
          sqls # sql
          tombi # toml
          typescript-go # js / ts
          powershell-editor-services # powershell
          tailwindcss-language-server # tailwind
          vue-language-server # vue
          yaml-language-server # yaml

          # Debuggers
          bashdb # bash
          delve # go
          lldb # c / c++ / rust
          netcoredbg # c# / f#
          vscode-js-debug # js / ts
          python314Packages.debugpy # python

          # Linters
          cfn-nag # yaml
          clippy # rust
          eslint_d # js / ts
          markdownlint-cli2 # markdown
          ruff # python
          yamllint # yaml

          # Formatters
          rustfmt # rust
          prettierd # js / ts
          php85Packages.php-cs-fixer # php
        ];
      };
    };
}
