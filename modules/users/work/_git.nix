{ secrets, ... }:

{
  programs = {
    git = {
      settings = {
        user = {
          name = "Matt Wilding";
          email = secrets.workEmailName;
          signingkey = "~/.ssh/work.pub";
        };
        url = {
          "git@${secrets.workName}.github.com:${secrets.workName}/" = {
            insteadOf = "git@github.com:${secrets.workName}/";
          };
          "git@${secrets.workName}.github.com:${secrets.workName}-shared-platform/" = {
            insteadOf = "git@github.com:${secrets.workName}-shared-platform/";
          };
          "git@${secrets.workName}.gitlab.com:${secrets.workName}/" = {
            insteadOf = "git@gitlab.com:${secrets.workName}/";
          };
        };
        includeIf = {
          "hasconfig:remote.*.url:git@gitlab.com:${secrets.workName}/**" = {
            path = "~/.config/git/config-gitlab";
          };
          "hasconfig:remote.*.url:git@github.com:mbwilding/**" = {
            path = "~/.config/git/config-personal";
          };
          "hasconfig:remote.*.url:git@git.mattwilding.com/**" = {
            path = "~/.config/git/config-personal";
          };
        };
      };
    };
  };

  home = {
    file = {
      ".config/git/config-gitlab".text = ''
        [user]
            name = Matt Wilding
            email = ${secrets.workEmailId}
            signingkey = ~/.ssh/work.pub
      '';

      ".config/git/config-personal".text = ''
        [user]
            name = Matthew Wilding
            email = mbwilding@gmail.com
            signingkey = ~/.ssh/personal.pub
      '';

      ".config/git/allowed_signers".text = ''
        ${secrets.workEmailName} ${secrets.workPublicKey}
        ${secrets.workEmailId} ${secrets.workPublicKey}
        mbwilding@gmail.com ${secrets.personalPublicKey}
      '';
    };
  };
}
