{ ... }:

{
  flake.modules.homeManager.ssh =
    { secrets, ... }:
    let
      personal = {
        identitiesOnly = true;
        identityFile = [ "~/.ssh/personal" ];
      };
      work = {
        identitiesOnly = true;
        identityFile = [ "~/.ssh/work" ];
      };
    in
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

            desktop = personal // {
              hostname = "192.168.11.254";
              user = "anon";
              forwardAgent = true;
            };

            vm = personal // {
              hostname = "192.168.122.130";
              user = "anon";
              forwardAgent = true;
            };

            nona = personal // {
              hostname = "192.168.11.60";
              user = "anon";
              forwardAgent = true;
            };

            truenas = personal // {
              hostname = "192.168.11.10";
              user = "root";
            };

            arch = personal // {
              hostname = "192.168.11.10";
              port = 2222;
              user = "anon";
              forwardAgent = true;
            };

            nix = personal // {
              hostname = "192.168.11.14";
              user = "anon";
            };

            phone = personal // {
              hostname = "192.168.11.41";
              port = 8022;
              user = "root";
            };

            "aur.archlinux.org" = {
              user = "aur";
              identitiesOnly = true;
              identityFile = [ "~/.ssh/aur" ];
            };

            "github.com" = personal // {
              user = "git";
            };

            "${secrets.workName}.github.com" = work // {
              hostname = "github.com";
              user = "git";
            };

            "gitlab.com" = personal // {
              hostname = "gitlab.com";
              user = "git";
            };

            "${secrets.workName}.gitlab.com" = work // {
              hostname = "gitlab.com";
              user = "git";
            };

            surface = personal // {
              hostname = "192.168.11.253";
            };

            "ssh.dev.azure.com" = work // {
              user = "git";
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
    };
}
