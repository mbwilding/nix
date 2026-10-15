{ ... }:

let
  personal = {
    IdentitiesOnly = true;
    IdentityFile = [ "~/.ssh/personal" ];
    User = "mbwilding";
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
        lxc = personal // { };
        nona = personal // { };
        server = personal // { };
        truenas = personal // { };
        stealth = personal // { };

        ai-sdlc = personal // {
          User = "agent";
        };

        # Git

        "github.com" = personal // {
          User = "git";
        };

        "gitlab.com" = personal // {
          User = "git";
        };

        "git.mattwilding.com" = personal // {
          User = "git";
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
}
