{ ... }:

let
  usernamePersonal = "mbwilding";
  usernameWork = builtins.readFile /home/anon/.secrets/github-work-username;
in
{
  programs = {
    gh = {
      enable = true;
      hosts = {
        "github.com" = {
          user = usernameWork;
          users = {
            "${usernamePersonal}" = {
              oauth_token = builtins.readFile /home/anon/.secrets/github-personal;
            };
            "${usernameWork}" = {
              oauth_token = builtins.readFile /home/anon/.secrets/github-work;
            };
          };
        };
      };
      settings = {
        aliases = {
          co = "pr checkout";
          pv = "pr view";
          pc = "pr create";
        };
        # version = 1;
        editor = "nvim";
        git_protocol = "ssh";
        color_labels = "enabled";
        browser = "google-chrome";
        pager = "delta";
        spinner = "enabled";
        prompt = "enabled";
        prefer_editor_prompt = "enabled";
      };
    };
  };
}
