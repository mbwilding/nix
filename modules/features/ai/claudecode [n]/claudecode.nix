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
            enabledPlugins = {
              "clangd-lsp@claude-plugins-official" = true;
              "csharp-lsp@claude-plugins-official" = true;
              "gopls-lsp@claude-plugins-official" = true;
              "jdtls-lsp@claude-plugins-official" = true;
              "kotlin-lsp@claude-plugins-official" = false;
              "lua-lsp@claude-plugins-official" = true;
              "php-lsp@claude-plugins-official" = false;
              "pyright-lsp@claude-plugins-official" = true;
              "ruby-lsp@claude-plugins-official" = false;
              "rust-analyzer-lsp@claude-plugins-official" = true;
              "swift-lsp@claude-plugins-official" = false;
              "typescript-lsp@claude-plugins-official" = true;
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
