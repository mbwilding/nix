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
            model = "llama-swap/qwythos-9b";
            small_model = "llama-swap/qwythos-9b-fast";
            provider = {
              llama-swap = {
                api = "openai";
                name = "Llama Swap";
                options = {
                  baseURL = "http://192.168.11.254:60000/v1";
                  apiKey = "not-needed";
                };
                models = {
                  "qwythos-9b-fast" = {
                    name = "Qwythos 9B Fast (Q6_K)";
                    id = "qwythos-9b-fast";
                    tool_call = true;
                    temperature = true;
                    reasoning = true;
                  };
                  "qwythos-9b" = {
                    name = "Qwythos 9B (Q8_0)";
                    id = "qwythos-9b";
                    tool_call = true;
                    temperature = true;
                    reasoning = true;
                  };
                };
              };
            };
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
