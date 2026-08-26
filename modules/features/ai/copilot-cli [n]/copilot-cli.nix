{ ... }:

{
  flake.modules.homeManager.copilot-cli =
    {
      secrets,
      work ? false,
      ...
    }:
    {
      programs = {
        github-copilot-cli = {
          enable = true;
          context = ../context.md;
          settings = {
            autoUpdate = false;
            includeCoAuthoredBy = false;
            renderMarkdown = true;
            mouse = true;
          };
          mcpServers = {
            github = {
              type = "http";
              url = "https://api.githubcopilot.com/mcp";
              headers = {
                Authorization = "Bearer ${if work then secrets.githubWorkToken else secrets.githubPersonalToken}";
              };
            };
          };
          agents = {
            ponytail = ../agent-ponytail.md;
          };
          skills = {
            commit = ../command-commit.md;
            doco = ../command-doco.md;
          };
        };
      };
    };
}
