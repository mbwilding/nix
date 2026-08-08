{ ... }:

{
  flake.modules.homeManager.gh =
    {
      secrets,
      secretsProfile ? "personal",
      ...
    }:

    let
      isWork = secretsProfile == "work";
      username = if isWork then secrets.githubWorkUsername else "mbwilding";
      token = if isWork then secrets.githubWorkToken else secrets.githubPersonalToken;
    in
    {
      programs = {
        gh = {
          enable = true;
          hosts = {
            "github.com" = {
              user = username;
              users = {
                "${username}" = {
                  oauth_token = token;
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
            browser = "google-chrome-stable";
            pager = "delta";
            spinner = "enabled";
            prompt = "enabled";
            prefer_editor_prompt = "enabled";
          };
        };
      };
    };
}
