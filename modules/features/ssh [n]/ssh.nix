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
            "*" = {
              Compression = true;
              ControlMaster = "auto";
              ControlPersist = "120";
              ServerAliveCountMax = 10;
              ServerAliveInterval = 20;
              TCPKeepAlive = "yes";
            };

            desktop = personal // {
              HostName = "192.168.11.254";
              User = "anon";
              ForwardAgent = true;
            };

            vm = personal // {
              HostName = "192.168.122.130";
              User = "anon";
              ForwardAgent = true;
            };

            nona = personal // {
              HostName = "192.168.11.60";
              User = "anon";
              ForwardAgent = true;
            };

            truenas = personal // {
              HostName = "192.168.11.10";
              User = "root";
            };

            arch = personal // {
              HostName = "192.168.11.10";
              Port = 2222;
              User = "anon";
              ForwardAgent = true;
            };

            nix = personal // {
              HostName = "192.168.11.14";
              User = "anon";
            };

            phone = personal // {
              HostName = "192.168.11.41";
              Port = 8022;
              User = "root";
            };

            "aur.archlinux.org" = {
              User = "aur";
              IdentitiesOnly = true;
              IdentityFile = [ "~/.ssh/aur" ];
            };

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

            surface = personal // {
              HostName = "192.168.11.253";
            };

            "ssh.dev.azure.com" = work // {
              User = "git";
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
