{ ... }:

{
  flake.modules.homeManager.ssh =
    { secrets, ... }:
    let
      personal = {
        IdentitiesOnly = true;
        IdentityFile = [ "~/.ssh/personal" ];
      };
      work = {
        IdentitiesOnly = true;
        IdentityFile = [ "~/.ssh/work" ];
      };
    in
    {
      programs = {
        ssh = {
          enable = true;
          enableDefaultConfig = false;

          settings = {
            # Devices

            desktop = personal // {
              HostName = "192.168.11.254";
              User = "anon";
            };

            nona = personal // {
              HostName = "192.168.11.60";
              User = "anon";
            };

            truenas = personal // {
              HostName = "192.168.11.10";
              User = "root";
            };

            surface = personal // {
              HostName = "192.168.11.253";
              TCPKeepAlive = "yes";
              ServerAliveCountMax = 10;
              ServerAliveInterval = 20;
            };

            # Git

            "github.com" = personal // {
              User = "git";
            };

            "${secrets.workName}.github.com" = work // {
              HostName = "github.com";
              User = "git";
            };

            "gitlab.com" = personal // {
              HostName = "gitlab.com";
              User = "git";
            };

            "${secrets.workName}.gitlab.com" = work // {
              HostName = "gitlab.com";
              User = "git";
            };

            "ssh.dev.azure.com" = work // {
              User = "git";
              PubkeyAcceptedKeyTypes = "+ssh-rsa";
              PasswordAuthentication = "no";
              ChallengeResponseAuthentication = "no";
              WarnWeakCrypto = "no";
            };

            "aur.archlinux.org" = {
              User = "aur";
              IdentitiesOnly = true;
              IdentityFile = [ "~/.ssh/aur" ];
            };
          };
        };
      };
    };
}
