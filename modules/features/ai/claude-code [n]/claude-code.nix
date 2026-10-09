{ ... }:

{
  flake.modules.homeManager.claude-code =
    {
      secrets,
      pkgsMaster,
      work ? false,
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
            model = "claude-sonnet-5-5";
            effortLevel = "medium";
            theme = "dark";
            enableAllProjectMcpServers = true;
            permissions = {
              defaultMode = "auto";
              allow = [
                "Bash"
                "Read"
                "Edit"
                "Write"
                "NotebookEdit"
                "WebFetch"
                "WebSearch"
                "Agent"
                "Skill"
                "ToolSearch"
                "Monitor"
                "TaskStop"
                "EnterPlanMode"
                "ExitPlanMode"
                "EnterWorktree"
                "ExitWorktree"
                "CronCreate"
                "CronDelete"
                "CronList"
                "ScheduleWakeup"
                "ListMcpResourcesTool"
                "ReadMcpResourceTool"
                "ReadMcpResourceDirTool"
                "mcp__plugin_hm_github__*"
                "mcp__claude-in-chrome__*"
              ];
            };
            # enabledPlugins = {
            #   "clangd-lsp@claude-plugins-official" = false;
            #   "csharp-lsp@claude-plugins-official" = true;
            #   "gopls-lsp@claude-plugins-official" = false;
            #   "jdtls-lsp@claude-plugins-official" = false;
            #   "kotlin-lsp@claude-plugins-official" = false;
            #   "lua-lsp@claude-plugins-official" = true;
            #   "php-lsp@claude-plugins-official" = false;
            #   "pyright-lsp@claude-plugins-official" = true;
            #   "ruby-lsp@claude-plugins-official" = false;
            #   "rust-analyzer-lsp@claude-plugins-official" = true;
            #   "swift-lsp@claude-plugins-official" = false;
            #   "typescript-lsp@claude-plugins-official" = true;
            # };
          };
          mcpServers = {
            github = {
              type = "http";
              url = "https://api.githubcopilot.com/mcp";
              headers = {
                Authorization = "Bearer ${if work then secrets.githubWorkToken else secrets.githubPersonalToken}";
              };
            };
          }
          // (
            if work then
              {
                atlassian = {
                  type = "http";
                  url = "https://mcp.atlassian.com/v1/mcp";
                };
                # lucid = {
                #   type = "http";
                #   url = "https://mcp.lucid.app/mcp";
                # };
              }
            else
              { }
          );
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
