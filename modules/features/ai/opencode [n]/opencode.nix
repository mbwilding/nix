{ ... }:

{
  flake.modules.homeManager.opencode =
    {
      secrets,
      secretsProfile ? "personal",
      ...
    }:
    let
      isWork = secretsProfile == "work";
    in
    {
      programs = {
        opencode = {
          enable = true;
          context = ../context.md;
          settings = {
            lsp = true;
            formatter = true;
            autoupdate = false;
            share = "manual";
            model = "github-copilot/claude-sonnet-5";
            small_model = "github-copilot/gpt-5-mini";
            # model = "llama-swap/qwythos-9b-abliterated";
            # small_model = "llama-swap/qwythos-9b-abliterated-fast";
            disabled_providers = [
              "opencode"
              "opencode-go"
              "gemini"
              "amazon-bedrock"
              "duo"
              "gitlab"
            ];
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
                enabled = false;
                type = "remote";
                url = "https://mcp.atlassian.com/v1/mcp";
              };
              github = {
                enabled = false;
                type = "remote";
                url = "https://api.githubcopilot.com/mcp";
                headers = {
                  Authorization = "Bearer ${if isWork then secrets.githubWorkToken else secrets.githubPersonalToken}";
                };
              };
              lucid = {
                enabled = false;
                type = "remote";
                url = "https://mcp.lucid.app/mcp";
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
          tui = {
            mouse = true;
            diff_style = "auto";
            attention = {
              enabled = true;
              notifications = true;
              sound = true;
              volume = 0.4;
            };
          };
        };
      };
    };
}
