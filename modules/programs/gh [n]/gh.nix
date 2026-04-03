{ ... }:

{
  flake.modules.homeManager.gh =
    { secrets, ... }:

    let
      usernamePersonal = "mbwilding";
      usernameWork = secrets.githubWorkUsername;
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
                  oauth_token = secrets.githubPersonalToken;
                };
                "${usernameWork}" = {
                  oauth_token = secrets.githubWorkToken;
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
    };
}
