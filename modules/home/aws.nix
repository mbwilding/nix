{ ... }:

let
  s = builtins.fromJSON (builtins.readFile /home/anon/.secrets/aws.json);
  output = "yaml";

  mkProfile =
    {
      name,
      account_id,
      default_role,
      roles ? [ ],
    }:
    let
      base = {
        sso_session = s.sso_session;
        sso_account_id = account_id;
        region = s.region;
        output = output;
      };
      defaultEntry = {
        "profile ${name}" = base // {
          sso_role_name = default_role;
        };
      };
      suffixedEntries = builtins.listToAttrs (
        map (role: {
          name = "profile ${name}-${builtins.replaceStrings [ "-elevated" ] [ "" ] role}";
          value = base // {
            sso_role_name = s.roles.${role};
          };
        }) roles
      );
    in
    defaultEntry // suffixedEntries;
in
{
  programs = {
    awscli = {
      enable = true;
      settings = {
        default = {
          aws_access_key_id = s.personal.id;
          aws_secret_access_key = s.personal.secret;
          region = s.region;
          output = output;
        };

        "sso-session ${s.sso_session}" = {
          sso_region = s.region;
          sso_start_url = s.sso_start_url;
          sso_registration_scopes = s.sso_registration_scopes;
        };
      }

      // mkProfile {
        name = "md";
        account_id = s.accounts.md;
        default_role = s.roles.power;
        roles = [
          "read"
          "power"
          "rds"
        ];
      }
      // mkProfile {
        name = "mt";
        account_id = s.accounts.mt;
        default_role = s.roles.power;
        roles = [
          "read"
          "power"
          "rds"
        ];
      }
      // mkProfile {
        name = "mq";
        account_id = s.accounts.mq;
        default_role = s.roles.read;
        roles = [
          "read"
          "power-elevated"
          "rds"
        ];
      }
      // mkProfile {
        name = "mp";
        account_id = s.accounts.mp;
        default_role = s.roles.read;
        roles = [
          "read"
          "power-elevated"
          "rds"
        ];
      }

      // mkProfile {
        name = "ws";
        account_id = s.accounts.ws;
        default_role = s.roles.power;
      }
      // mkProfile {
        name = "wd";
        account_id = s.accounts.wd;
        default_role = s.roles.power;
      }
      // mkProfile {
        name = "wt";
        account_id = s.accounts.wt;
        default_role = s.roles.power;
      }
      // mkProfile {
        name = "wq";
        account_id = s.accounts.wq;
        default_role = s.roles.read;
        roles = [
          "power-elevated"
          "secrets-elevated"
        ];
      }
      // mkProfile {
        name = "wp";
        account_id = s.accounts.wp;
        default_role = s.roles.read;
        roles = [
          "power-elevated"
          "secrets-elevated"
        ];
      }

      // mkProfile {
        name = "rs";
        account_id = s.accounts.rs;
        default_role = s.roles.power;
      }
      // mkProfile {
        name = "rd";
        account_id = s.accounts.rd;
        default_role = s.roles.power;
      }
      // mkProfile {
        name = "rt";
        account_id = s.accounts.rt;
        default_role = s.roles.power;
      }
      // mkProfile {
        name = "rq";
        account_id = s.accounts.rq;
        default_role = s.roles.read;
        roles = [
          "power-elevated"
          "secrets-elevated"
        ];
      }
      // mkProfile {
        name = "rp";
        account_id = s.accounts.rp;
        default_role = s.roles.read;
        roles = [
          "power-elevated"
          "secrets-elevated"
        ];
      }

      // mkProfile {
        name = "fd";
        account_id = s.accounts.fd;
        default_role = s.roles.read;
        roles = [
          "power-elevated"
          "secrets-elevated"
        ];
      }
      // mkProfile {
        name = "fa";
        account_id = s.accounts.fa;
        default_role = s.roles.read;
        roles = [
          "power-elevated"
          "secrets-elevated"
        ];
      }
      // mkProfile {
        name = "fs";
        account_id = s.accounts.fs;
        default_role = s.roles.read;
        roles = [
          "power-elevated"
          "secrets-elevated"
        ];
      }
      // mkProfile {
        name = "fp";
        account_id = s.accounts.fp;
        default_role = s.roles.read;
        roles = [
          "power-elevated"
          "secrets-elevated"
        ];
      }

      // mkProfile {
        name = "ss";
        account_id = s.accounts.ss;
        default_role = s.special_roles.ss;
        roles = [
          "read"
          "power-elevated"
          "secrets-elevated"
        ];
      }

      // mkProfile {
        name = "sc";
        account_id = s.accounts.sc;
        default_role = s.roles.read;
        roles = [
          "read"
          "power-elevated"
          "secrets-elevated"
        ];
      }

      // mkProfile {
        name = "ma";
        account_id = s.accounts.ma;
        default_role = s.roles.read;
      }

      // mkProfile {
        name = "cd";
        account_id = s.accounts.cd;
        default_role = s.special_roles.cd;
        roles = [
          "secrets-elevated"
          "read"
        ];
      }

      // mkProfile {
        name = "gc";
        account_id = s.accounts.gc;
        default_role = s.special_roles.gc;
      };
    };
  };
}
