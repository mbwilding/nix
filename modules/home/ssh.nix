{ secrets, ... }:

{
  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = {
        "*" = {
          compression = true;
          controlMaster = "auto";
          controlPersist = "120";
          serverAliveCountMax = 10;
          serverAliveInterval = 20;
          extraOptions = {
            TCPKeepAlive = "yes";
          };
        };

        desktop = {
          hostname = "192.168.11.254";
          user = "anon";
          forwardAgent = true;
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        vm = {
          hostname = "192.168.122.130";
          user = "anon";
          forwardAgent = true;
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        nona = {
          hostname = "192.168.11.60";
          user = "anon";
          forwardAgent = true;
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        sara = {
          hostname = "192.168.11.218";
          user = "sara";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        sara-root = {
          hostname = "192.168.11.218";
          user = "root";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        truenas = {
          hostname = "192.168.11.10";
          user = "root";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        arch = {
          hostname = "192.168.11.10";
          port = 2222;
          user = "anon";
          forwardAgent = true;
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        nix = {
          hostname = "192.168.11.14";
          user = "anon";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        phone = {
          hostname = "192.168.11.41";
          port = 8022;
          user = "root";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        "aur.archlinux.org" = {
          user = "aur";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/aur" ];
        };

        "github.com" = {
          user = "git";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        "${secrets.workName}.github.com" = {
          hostname = "github.com";
          user = "git";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/work" ];
        };

        "gitlab.com" = {
          hostname = "gitlab.com";
          user = "git";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/work" ];
        };

        surface = {
          hostname = "192.168.11.253";
          user = "tabmaw";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/personal" ];
        };

        "ssh.dev.azure.com" = {
          user = "git";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/work" ];
          extraOptions = {
            PubkeyAcceptedKeyTypes = "+ssh-rsa";
            PasswordAuthentication = "no";
            ChallengeResponseAuthentication = "no";
            WarnWeakCrypto = "no";
          };
        };
      };
    };
  };
}
