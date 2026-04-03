{ ... }:

{
  flake.modules.homeManager.git =
    { secrets, config, ... }:

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
              re = "reset --hard";
              rb = "rebase";
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
            interactive.diffFilter = "delta --color-only";
            push.autoSetupRemote = true;
            delta = {
              navigate = true;
              dark = true;
              "side-by-side" = true;
            };
            diff = {
              tool = "nvim";
              algorithm = "histogram";
            };
            "difftool \"nvim\"".cmd = "nvim -d \"$LOCAL\" \"$REMOTE\" -c \"CodeDiff\"";
            difftool.prompt = false;
            merge.tool = "vscode-diff";
            "mergetool \"vscode-diff\"".cmd = "nvim \"$MERGED\" -c 'CodeDiff merge \"$MERGED\"'";
            "filter \"lfs\"" = {
              process = "git-lfs filter-process";
              required = true;
              clean = "git-lfs clean -- %f";
              smudge = "git-lfs smudge -- %f";
            };
            url = {
              "git@${secrets.workName}.github.com:${secrets.workName}/" = {
                insteadOf = "git@github.com:${secrets.workName}/";
              };
            };
            includeIf = {
              "hasconfig:remote.*.url:**" = {
                path = "~/.config/git/config-personal";
              };
              "hasconfig:remote.*.url:git@gitlab.com:${secrets.workName}/**" = {
                path = "~/.config/git/config-work";
              };
              # NOTE: May need work to be upper
              "hasconfig:remote.*.url:git@ssh.dev.azure.com:v*/${secrets.workName}/**" = {
                path = "~/.config/git/config-work";
              };
              "hasconfig:remote.*.url:git@github.com:${secrets.workName}/**" = {
                path = "~/.config/git/config-work";
              };
              "hasconfig:remote.*.url:git@${secrets.workName}.github.com:${secrets.workName}/**" = {
                path = "~/.config/git/config-work";
              };
            };
          };
        };
      };

      home = {
        file.".config/git/config-personal".text = ''
          [user]
              name = Matthew Wilding
              email = mbwilding@gmail.com
              signingkey = ~/.ssh/personal.pub
        '';

        file.".config/git/config-work".text = ''
          [user]
              name = Matt Wilding
              email = ${secrets.workEmailName}
              signingkey = ~/.ssh/work.pub
        '';

        file.".config/git/allowed_signers".text = ''
          mbwilding@gmail.com ${secrets.personalPublicKey}
          ${secrets.workEmailName} ${secrets.workPublicKey}
        '';
      };
    };
}
