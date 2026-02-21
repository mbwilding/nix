{ ... }:
let
  work = builtins.readFile /home/anon/.secrets/work-name;
  workEmailName = builtins.readFile /home/anon/.secrets/work-email-name;
in
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
      ];
      settings = {
        gpg = {
          format = "ssh";
          "ssh" = {
            allowedSignersFile = "/home/anon/.config/git/allowed_signers";
          };
        };
        commit.gpgsign = true;
        alias = {
          c = "clone --recursive --depth 1";
          r = "reset --hard";
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
          "git@${work}.github.com:${work}/" = {
            insteadOf = "git@github.com:${work}/";
          };
        };
        includeIf = {
          "hasconfig:remote.*.url:**" = {
            path = "~/.config/git/config-personal";
          };
          "hasconfig:remote.*.url:git@gitlab.com:${work}/**" = {
            path = "~/.config/git/config-work";
          };
          # NOTE: May need work to be upper
          "hasconfig:remote.*.url:git@ssh.dev.azure.com:v*/${work}/**" = {
            path = "~/.config/git/config-work";
          };
          "hasconfig:remote.*.url:git@github.com:${work}/**" = {
            path = "~/.config/git/config-work";
          };
          "hasconfig:remote.*.url:git@${work}.github.com:${work}/**" = {
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
          email = ${workEmailName}
          signingkey = ~/.ssh/work.pub
    '';

    file.".config/git/allowed_signers".text = ''
      mbwilding@gmail.com ${builtins.readFile /home/anon/.ssh/personal.pub}
      ${workEmailName} ${builtins.readFile /home/anon/.ssh/work.pub}
    '';
  };
}
