{ ... }:

{
  flake.modules.homeManager.opencode =
    {
      pkgsMaster,
      secrets,
      ...
    }:
    {
      programs = {
        opencode = {
          enable = true;
          package = pkgsMaster.opencode;
          context = ./context.md;
          settings = {
            lsp = true;
            permission = {
              # allow, deny, ask
              bash = "allow";
              edit = "allow";
              glob = "allow";
              grep = "allow";
              lsp = "allow";
              question = "allow";
              read = "allow";
              skill = "allow";
              todowrite = "allow";
              webfetch = "allow";
              websearch = "deny"; # NOTE: Requires EXA AI and OPENCODE_ENABLE_EXA=true
            };
            mcp = {
              atlassian = {
                type = "remote";
                url = "https://mcp.atlassian.com/v1/mcp";
              };
              github-personal = {
                type = "remote";
                url = "https://api.githubcopilot.com/mcp";
                headers = {
                  Authorization = "Bearer ${secrets.githubPersonalToken}";
                };
              };
              github-work = {
                type = "remote";
                url = "https://api.githubcopilot.com/mcp";
                headers = {
                  Authorization = "Bearer ${secrets.githubWorkToken}";
                };
              };
              lucid = {
                type = "remote";
                url = "https://mcp.lucid.app/mcp";
              };
            };
          };
          agents = {
            ponytail = ./agents/ponytail.md;
          };
          commands = {
            commit = ./commands/commit.md;
            doco = ./commands/doco.md;
          };
        };
      };
    };
}
