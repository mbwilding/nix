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
          bun # js / ts
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
          pnpm # js / ts
          python314 # python
          ruby # ruby
          rustc # rust
          uv # python
          yarn-berry # js / ts

          # Language Servers
          bash-language-server # bash
          docker-compose-language-service # yaml
          docker-language-server # docker
          gopls # go
          jdt-language-server # java
          lemminx # xml
          lua-language-server # lua
          marksman # markdown
          nil # nix
          phpactor # php
          powershell-editor-services # powershell
          pyright # python
          qt6.qtdeclarative # qml (qmlls)
          roslyn-ls # c#
          rust-analyzer # rust
          sqls # sql
          tailwindcss-language-server # tailwind
          tombi # toml
          typescript-go # js / ts
          vscode-langservers-extracted # css / html / json (vscode-*-language-server)
          vue-language-server # vue
          yaml-language-server # yaml
          zls # zig

          # Debuggers
          bashdb # bash
          delve # go
          lldb # c / c++ / rust
          netcoredbg # c# / f#
          python314Packages.debugpy # python
          vscode-js-debug # js / ts

          # Linters
          cfn-nag # yaml
          clippy # rust
          eslint_d # js / ts
          markdownlint-cli2 # markdown
          python313Packages.cfn-lint # python
          ruff # python
          yamllint # yaml

          # Formatters
          php85Packages.php-cs-fixer # php
          prettierd # js / ts
          rustfmt # rust

          # Misc
          quicktype # json to lang

          # TODO: Find these
          # vscode-bash-debug
          # vscode-extensions.ms-vscode.powershell
          # vscode-extensions.llvm-vs-code-extensions.lldb-dap
        ];
      };
    };
}
