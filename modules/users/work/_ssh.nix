{ secrets, ... }:

let
  work = {
    IdentitiesOnly = true;
    IdentityFile = [ "~/.ssh/work" ];
    User = "git";
  };
in
{
  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
        # Git

        "${secrets.workName}.github.com" = work // {
          HostName = "github.com";
          User = "git";
        };

        "${secrets.workName}.gitlab.com" = work // {
          HostName = "gitlab.com";
        };

        "github.com" = {
          IdentitiesOnly = true;
          IdentityFile = [ "~/.ssh/personal" ];
          User = "git";
        };

        "ssh.dev.azure.com" = work // {
          PubkeyAcceptedKeyTypes = "+ssh-rsa";
          PasswordAuthentication = "no";
          ChallengeResponseAuthentication = "no";
          WarnWeakCrypto = "no";
        };
      };
    };
  };
}
