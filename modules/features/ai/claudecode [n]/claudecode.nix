{ ... }:

{
  flake.modules.homeManager.claudecode =
    {
      pkgsMaster,
      secrets,
      ...
    }:
    {
      programs = {
        claude-code = {
          enable = true;
          package = pkgsMaster.claude-code;
          context = ../context.md;
          settings = {
            includeCoAuthoredBy = false;
            disableClaudeAiConnectors = true;
            model = "claude-sonnet-5";
            theme = "dark";
            permissions = {
              defaultMode = "auto";
            };
          };
          mcpServers = {
            github = {
              type = "http";
              url = "https://api.githubcopilot.com/mcp";
              headers = {
                Authorization = "Bearer ${secrets.githubPersonalToken}";
              };
            };
          };
          agents = {
            ponytail = ../agent-ponytail.md;
          };
          commands = {
            commit = ../command-commit.md;
            doco = ../command-doco.md;
          };
        };
      };
    };
}
