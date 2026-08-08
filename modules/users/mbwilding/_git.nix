{ secrets, ... }:

{
  programs = {
    git = {
      settings = {
        user = {
          name = "Matthew Wilding";
          email = "mbwilding@gmail.com";
          signingkey = "~/.ssh/personal.pub";
        };
      };
    };
  };

  home = {
    file = {
      ".config/git/allowed_signers".text = ''
        mbwilding@gmail.com ${secrets.personalPublicKey}
      '';
    };
  };
}
