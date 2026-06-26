{ inputs, ... }:

{
  flake.modules.homeManager.yazi =
    { config, pkgs, ... }:
    let
      extractToDir = pkgs.writeShellScriptBin "yazi-extract-dir" ''
        file="$1"
        dir="$(dirname "$file")"
        stem="$(basename "$file")"
        stem="''${stem%%.*}"
        7z x "$file" -o"$dir/$stem"
      '';
    in
    {
      home.packages = [ extractToDir ];
      programs.yazi = {
        enable = true;
        package = inputs.yazi.packages.${pkgs.stdenv.hostPlatform.system}.default;
        enableZshIntegration = config.programs.zsh.enable;
        enableFishIntegration = config.programs.fish.enable;
        shellWrapperName = "y";
        plugins = {
          git = pkgs.yaziPlugins.git;
          githead = pkgs.yaziPlugins.githead;
          bookmarks = pkgs.yaziPlugins.bookmarks;
          bypass = pkgs.yaziPlugins.bypass;
          chmod = pkgs.yaziPlugins.chmod;
          clipboard = pkgs.yaziPlugins.clipboard;
          compress = pkgs.yaziPlugins.compress;
          convert = pkgs.yaziPlugins.convert;
          gitui = pkgs.yaziPlugins.gitui;
          gvfs = pkgs.yaziPlugins.gvfs;
          lazygit = pkgs.yaziPlugins.lazygit;
          lsar = pkgs.yaziPlugins.lsar;
          mediainfo = pkgs.yaziPlugins.mediainfo;
          mount = pkgs.yaziPlugins.mount;
          office = pkgs.yaziPlugins.office;
          "omni-trash" = pkgs.yaziPlugins.omni-trash;
          ouch = pkgs.yaziPlugins.ouch;
          rsync = pkgs.yaziPlugins.rsync;
          "smart-paste" = pkgs.yaziPlugins.smart-paste;
          sshfs = pkgs.yaziPlugins.sshfs;
          sudo = pkgs.yaziPlugins.sudo;
        };
        settings = {
          opener = {
            view = [
              {
                run = ''imv "%s"'';
                desc = "View image";
                orphan = true;
              }
            ];
            edit = [
              {
                run = ''nvim "%s"'';
                desc = "Edit with nvim";
                block = true;
              }
            ];
            browse = [
              {
                run = ''
                  tmp=$(mktemp -d)
                  archivemount "%s" "$tmp"
                  yazi "$tmp"
                  fusermount -u "$tmp"
                  rmdir "$tmp"
                '';
                desc = "Browse archive";
                block = true;
              }
            ];
            extract = [
              {
                run = ''yazi-extract-dir "%s1"'';
                desc = "Extract to directory";
              }
            ];
            extract-here = [
              {
                run = ''7z x "%s1" -o"%d1"'';
                desc = "Extract here";
              }
            ];
            wine = [
              {
                run = "wine %s";
                desc = "Run with Wine";
                orphan = true;
              }
            ];
          };
          open = {
            prepend_rules = [
              {
                url = "*.exe";
                use = "wine";
              }
              {
                url = "*.msi";
                use = "wine";
              }
              {
                mime = "application/x-dosexec";
                use = "wine";
              }
              {
                mime = "application/vnd.microsoft.portable-executable";
                use = "wine";
              }
              {
                mime = "application/x-msi";
                use = "wine";
              }
              {
                mime = "image/*";
                use = "view";
              }
              {
                mime = "text/*";
                use = "edit";
              }
              {
                mime = "application/json";
                use = "edit";
              }
              {
                mime = "application/zip";
                use = [
                  "browse"
                  "extract"
                  "extract-here"
                ];
              }
              {
                mime = "application/gzip";
                use = [
                  "browse"
                  "extract"
                  "extract-here"
                ];
              }
              {
                mime = "application/x-tar";
                use = [
                  "browse"
                  "extract"
                  "extract-here"
                ];
              }
              {
                mime = "application/x-bzip2";
                use = [
                  "browse"
                  "extract"
                  "extract-here"
                ];
              }
              {
                mime = "application/x-xz";
                use = [
                  "browse"
                  "extract"
                  "extract-here"
                ];
              }
              {
                mime = "application/x-zstd";
                use = [
                  "browse"
                  "extract"
                  "extract-here"
                ];
              }
              {
                mime = "application/x-7z-compressed";
                use = [
                  "browse"
                  "extract"
                  "extract-here"
                ];
              }
              {
                mime = "application/vnd.rar";
                use = [
                  "browse"
                  "extract"
                  "extract-here"
                ];
              }
              {
                mime = "application/x-rar-compressed";
                use = [
                  "browse"
                  "extract"
                  "extract-here"
                ];
              }
            ];
          };
          mgr = {
            linemode = "permissions";
            scrolloff = 3;
            show_hidden = true;
            show_symlink = true;
            sort_by = "alphabetical";
            sort_dir_first = true;
            sort_reverse = false;
            sort_sensitive = true;
            title_format = "{cwd}";
            mouse_events = [
              "click"
              "scroll"
              "touch"
              "move"
              "drag"
            ];
          };
          preview = {
            wrap = "yes";
            tab_size = 2;
            max_width = 9999;
            max_height = 9999;
            image_filter = "lanczos3";
            image_quality = 90;
          };
        };
        keymap = {
          mgr.prepend_keymap = [
            {
              on = "x";
              run = ''shell -- yazi-extract-dir "%h"'';
              desc = "Extract archive to directory";
            }
            {
              on = "X";
              run = ''shell -- 7z x "%h" -o"%d1"'';
              desc = "Extract archive here";
            }
            {
              on = [ "g" "s" ];
              run = "plugin git";
              desc = "Git status";
            }
            {
              on = [ "g" "h" ];
              run = "plugin githead";
              desc = "Git HEAD details";
            }
            {
              on = [ "g" "u" ];
              run = "plugin gitui";
              desc = "Open gitui";
            }
            {
              on = [ "g" "l" ];
              run = "plugin lazygit";
              desc = "Open lazygit";
            }
            {
              on = [ "b" "m" ];
              run = "plugin bookmarks";
              desc = "Bookmarks";
            }
            {
              on = [ "b" "p" ];
              run = "plugin bypass";
              desc = "Bypass operations";
            }
            {
              on = [ "c" "h" ];
              run = "plugin chmod";
              desc = "Change permissions";
            }
            {
              on = [ "c" "l" ];
              run = "plugin clipboard";
              desc = "Clipboard";
            }
            {
              on = [ "c" "o" ];
              run = "plugin compress";
              desc = "Compress";
            }
            {
              on = [ "c" "v" ];
              run = "plugin convert";
              desc = "Convert files";
            }
            {
              on = [ "m" "m" ];
              run = "plugin mediainfo";
              desc = "Media info";
            }
            {
              on = [ "m" "o" ];
              run = "plugin mount";
              desc = "Mount manager";
            }
            {
              on = [ "f" "s" ];
              run = "plugin gvfs";
              desc = "GVFS mounts";
            }
            {
              on = [ "o" "f" ];
              run = "plugin office";
              desc = "Office preview";
            }
            {
              on = [ "t" "r" ];
              run = "plugin omni-trash";
              desc = "Trash actions";
            }
            {
              on = [ "a" "r" ];
              run = "plugin ouch";
              desc = "Archive with ouch";
            }
            {
              on = [ "r" "s" ];
              run = "plugin rsync";
              desc = "Rsync";
            }
            {
              on = [ "p" "s" ];
              run = "plugin smart-paste";
              desc = "Smart paste";
            }
            {
              on = [ "s" "f" ];
              run = "plugin sshfs";
              desc = "SSHFS";
            }
            {
              on = [ "s" "u" ];
              run = "plugin sudo";
              desc = "Sudo actions";
            }
            {
              on = [ "a" "l" ];
              run = "plugin lsar";
              desc = "Archive listing";
            }
          ];
        };
      };
    };
}
