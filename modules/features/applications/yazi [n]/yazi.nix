{ ... }:

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
        enableZshIntegration = config.programs.zsh.enable;
        enableFishIntegration = config.programs.fish.enable;
        shellWrapperName = "y";
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
          };
          open = {
            prepend_rules = [
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
          ];
        };
      };
    };
}
