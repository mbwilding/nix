{ ... }:

{
  flake.modules.homeManager.git =
    {
      config,
      pkgs,
      ...
    }:

    {
      services = {
        gpg-agent = {
          enable = true;
          enableSshSupport = true;
        };
      };

      programs = {
        gpg.enable = true;
        git = {
          enable = true;
          lfs.enable = true;
          ignores = [
            "*~"
            "*.swp"
            "*.idea/"
            "*.claude/"
          ];
          settings = {
            gpg = {
              format = "ssh";
              "ssh" = {
                allowedSignersFile = "${config.home.homeDirectory}/.config/git/allowed_signers";
              };
            };
            commit.gpgsign = true;
            alias = {
              am = "commit --amend";
              bc = "git branch --create";
              bcf = "git branch --force-create";
              bd = "git branch --delete";
              bdf = "git branch --delete --force";
              br = "branch";
              cl = "clone --recursive";
              co = "checkout";
              di = "diff";
              lo = "log --oneline --graph --decorate=full --format='%C(auto)%h %C(bold blue)%an %C(reset)%s'";
              ll = "log -1 HEAD";
              me = "merge";
              pu = "pull";
              pa = "format-patch";
              pr = "pull --rebase";
              rb = "rebase";
              rh = "reset --hard";
              st = "status";
              sw = "switch";
              un = "reset --soft HEAD~1";
              wta = "worktree add";
              wtl = "worktree list";
              wtr = "worktree remove";
            };
            init.defaultBranch = "main";
            core = {
              editor = "nvim";
              autocrlf = false;
              pager = "delta";
            };
            push = {
              autoSetupRemote = true;
              recurseSubmodules = "no";
            };
            submodule.recurse = true;
            delta = {
              navigate = true;
              dark = true;
              "side-by-side" = true;
            };
            interactive.diffFilter = "delta --color-only";
            diff = {
              tool = "nvim";
              algorithm = "histogram";
            };
            "difftool \"nvim\"".cmd = "nvim -d \"$LOCAL\" \"$REMOTE\" -c \"CodeDiff\"";
            difftool.prompt = false;
            merge.tool = "vscode-diff";
            "mergetool \"vscode-diff\"".cmd = "nvim \"$MERGED\" -c 'CodeDiff merge \"$MERGED\"'";
          };
        };
      };

      home = {
        packages = with pkgs; [
          delta
        ];
      };
    };
}
