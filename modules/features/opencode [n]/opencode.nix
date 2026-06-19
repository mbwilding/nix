{ ... }:

{
  flake.modules.homeManager.opencode =
    {
      lib,
      pkgs,
      pkgsMaster,
      secrets,
      ...
    }:
    let
      opencodeConfigDir = "$HOME/.config/opencode";

      opencodeJson = pkgs.writeText "opencode.json" (
        builtins.toJSON {
          "$schema" = "https://opencode.ai/config.json";
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
        }
      );
    in
    {
      programs = {
        opencode = {
          enable = true;
          package = pkgsMaster.opencode;
          context = ''
            Use Australian English at all times and avoid em dashes
            When writing Markdown files, don't add --- as separators
          '';
          agents = {
            document = ''
              # Documentation Writer Agent

              As an AI agent focused on technical documentation, your task is to analyse files, regardless of whether they are staged, unstaged, or simply reflect the current implementation—to produce clear, accurate, and maintainable documentation.
              You may also be asked to evaluate existing documentation against the current state of the codebase.

              ## Responsibilities
              - State the purpose (why) of each code section or module
              - Describe what the code does, including inputs, outputs, and side effects
              - Specify when and under what conditions the code should be used or updated
              - Keep documentation concise, accurate, and easy to follow
              - Recommend improvements for clarity, completeness, and maintainability
              - Conforms to the existing documentation style found in the repository.
            '';
          };
          commands = {
            # fix-issue = ./commands/fix-issue.md;
            changelog = ''
              # Update Changelog Command

              Update CHANGELOG.md with a new entry for the specified version.
              Usage: /changelog [version] [change-type] [message]
            '';
            commit = ''
              # Commit Command

              Create a git commit with proper message formatting in Australian English.
              Check the latest 10 commits and follow suit.
              Usage: /commit [message]
            '';
          };
        };
      };

      home.activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "${opencodeConfigDir}"

        if [ ! -f "${opencodeConfigDir}/opencode.json" ]; then
          $DRY_RUN_CMD cp ${opencodeJson} "${opencodeConfigDir}/opencode.json"
        fi
      '';
    };
}
