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
