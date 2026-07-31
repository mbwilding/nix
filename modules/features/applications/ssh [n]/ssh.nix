{ ... }:

{
  flake.modules.homeManager.ssh =
    { secrets, ... }:
    let
      personal = {
        IdentitiesOnly = true;
        IdentityFile = [ "~/.ssh/personal" ];
        User = "mbwilding";
      };
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
            # Devices

            anon = personal // { };

            nona = personal // { };

            truenas = personal // { };

            server = personal // { };

            phone = personal // {
              Port = 8022;
              User = "nix-on-droid";
            };

            surface = personal // {
              TCPKeepAlive = "yes";
              ServerAliveCountMax = 10;
              ServerAliveInterval = 20;
            };

            ai-sdlc = personal // {
              User = "root";
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
              User = "git";
            };

            "${secrets.workName}.gitlab.com" = work // {
              HostName = "gitlab.com";
            };

            "git.mattwilding.com" = personal // {
              User = "git";
            };

            "ssh.dev.azure.com" = work // {
              PubkeyAcceptedKeyTypes = "+ssh-rsa";
              PasswordAuthentication = "no";
              ChallengeResponseAuthentication = "no";
              WarnWeakCrypto = "no";
            };

            # Custom

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
