{ ... }:

{
  flake.modules.nixos.development =
    { pkgs, ... }:
    let
      buildInputs = [
        "${pkgs.alsa-lib.dev}/lib/pkgconfig"
        "${pkgs.fontconfig.dev}/lib/pkgconfig"
        "${pkgs.gtk3.dev}/lib/pkgconfig"
        "${pkgs.librsvg.dev}/lib/pkgconfig"
        "${pkgs.libusb1.dev}/lib/pkgconfig"
        "${pkgs.libGL.dev}/lib/pkgconfig"
        "${pkgs.libx11.dev}/lib/pkgconfig"
        "${pkgs.libxcursor}/lib/pkgconfig"
        "${pkgs.libxext.dev}/lib/pkgconfig"
        "${pkgs.libxi.dev}/lib/pkgconfig"
        "${pkgs.libxinerama.dev}/lib/pkgconfig"
        "${pkgs.libxkbcommon}/lib/pkgconfig"
        "${pkgs.libxrandr.dev}/lib/pkgconfig"
        "${pkgs.libxrender.dev}/lib/pkgconfig"
        "${pkgs.libsoup_3.dev}/lib/pkgconfig"
        "${pkgs.openssl.dev}/lib/pkgconfig"
        "${pkgs.pipewire.dev}/lib/pkgconfig"
        "${pkgs.webkitgtk_4_1.dev}/lib/pkgconfig"
        "${pkgs.wayland}/lib/pkgconfig"
        "${pkgs.wayland-protocols}/share/pkgconfig"
      ];
      runtimeLibs = [
        "${pkgs.alsa-lib}/lib"
        "${pkgs.fontconfig.lib}/lib"
        "${pkgs.gtk3}/lib"
        "${pkgs.librsvg}/lib"
        "${pkgs.libusb1}/lib"
        "${pkgs.libGL}/lib"
        "${pkgs.libICE}/lib"
        "${pkgs.libSM}/lib"
        "${pkgs.libx11}/lib"
        "${pkgs.libxcursor}/lib"
        "${pkgs.libxext}/lib"
        "${pkgs.libxi}/lib"
        "${pkgs.libxinerama}/lib"
        "${pkgs.libxkbcommon}/lib"
        "${pkgs.libxrandr}/lib"
        "${pkgs.libxrender}/lib"
        "${pkgs.libxshmfence}/lib"
        "${pkgs.libsoup_3}/lib"
        "${pkgs.pipewire}/lib"
        "${pkgs.webkitgtk_4_1}/lib"
      ];
    in
    {
      environment = {
        variables = {
          PKG_CONFIG_PATH = builtins.concatStringsSep ":" buildInputs;
        };
        sessionVariables = {
          PKG_CONFIG_PATH = builtins.concatStringsSep ":" buildInputs;
        };
        extraInit = ''
          export LD_LIBRARY_PATH="${builtins.concatStringsSep ":" runtimeLibs}:$LD_LIBRARY_PATH"
        '';
        systemPackages = with pkgs; [
          alsa-lib
          alsa-lib.dev
          cacert
          cifs-utils
          coreutils
          fontconfig
          gtk3
          gtk3.dev
          icu
          librsvg
          librsvg.dev
          libusb1
          libusb1.dev
          libGL
          libICE
          libSM
          libva
          libva-utils
          libx11
          libxcursor
          libxext
          libxi
          libxinerama
          libxkbcommon
          libxrandr
          libxrender
          libxshmfence
          libsoup_3
          libsoup_3.dev
          openssl
          openssl.dev
          pipewire
          pipewire.dev
          pkg-config
          skia
          webkitgtk_4_1
          webkitgtk_4_1.dev
          wayland
          wayland-protocols
        ];
      };

      programs = {
        nix-ld = {
          enable = true;
          libraries = with pkgs; [
            icu
            stdenv.cc.cc.lib # libstdc++.so.6
            glib # libglib-2.0, libgobject-2.0, libgio-2.0
            nss # libnss3, libnssutil3, libsmime3
            nspr # libnspr4
            dbus # libdbus-1
            at-spi2-atk # libatk-bridge-2.0
            atk # libatk-1.0, libatspi
            libdrm # libdrm
            libx11 # libX11
            libxcomposite # libXcomposite
            libxdamage # libXdamage
            libxext # libXext
            libxfixes # libXfixes
            libxrandr # libXrandr
            libgbm # libgbm
            wayland # wayland display protocol
            wayland-protocols
            libglvnd # libGL
            expat # libexpat
            libxcb # libxcb
            libxkbcommon # libxkbcommon
            pango # libpango-1.0
            cairo # libcairo
            alsa-lib # libasound
            cups # libcups
            gtk3 # libgtk-3
            libusb1 # libusb-1.0
            librsvg # librsvg-2
            libsoup_3 # libsoup-3.0
            pipewire # libpipewire-0.3
            webkitgtk_4_1 # libwebkit2gtk-4.1
          ];
        };
      };
    };

  flake.modules.homeManager.development =
    {
      pkgs,
      pkgsStable,
      pkgsMaster,
      ...
    }:
    let
      vscode-bash-debug = pkgs.callPackage ./_vscode-bash-debug.nix { };
      vscode-langservers-extracted = pkgs.callPackage ./_vscode-langservers-extracted.nix { };
      gh-actions-language-server = pkgs.callPackage ./_gh-actions-language-server.nix { };
    in
    {
      home = {
        packages = with pkgs; [
          # Shells
          powershell

          # Utilities
          scc # Code counter and complexity calculator

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
          jdk25 # java / kotlin
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
          gh-actions-language-server # yaml
          gopls # go
          jdt-language-server # java
          lemminx # xml
          lua-language-server # lua
          marksman # markdown
          nixd # nix
          phpactor # php
          powershell-editor-services # powershell
          pyright # python
          qt6.qtdeclarative # qml (qmlls)
          roslyn-ls # c#
          rust-analyzer # rust
          sqls # sql
          tailwindcss-language-server # tailwind
          tombi # toml
          pkgsMaster.typescript-go # js / ts
          vscode-langservers-extracted # css / html / json (vscode-*-language-server)
          vue-language-server # vue
          yaml-language-server # yaml
          zls # zig

          # Debuggers
          bashdb # bash
          delve # go
          lldb # c / c++ / rust / zig
          vscode-extensions.vadimcn.vscode-lldb.adapter # c / c++ / rust / zig
          netcoredbg # c# / f#
          python314Packages.debugpy # python
          powershell-editor-services # powershell
          vscode-js-debug # js / ts
          vscode-bash-debug # bash

          # Linters
          cfn-nag # yaml
          clippy # rust
          eslint_d # js / ts
          markdownlint-cli2 # markdown
          python313Packages.cfn-lint # python
          ruff # python
          yamllint # yaml

          # Formatters
          nixfmt-rs # nix
          php85Packages.php-cs-fixer # php
          prettierd # js / ts
          rustfmt # rust
        ];
      };
    };
}
