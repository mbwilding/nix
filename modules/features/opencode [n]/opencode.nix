{ ... }:

{
  flake.modules.homeManager.opencode =
    { pkgsMaster, ... }:
    {
      programs = {
        opencode = {
          enable = true;
          package = pkgsMaster.opencode;
          enableMcpIntegration = true;
          context = ''
            Use Australian English at all times and avoid em dashes
            When writing Markdown files, don't add --- as separators
          '';
          # context = builtins.replaceStrings ["nvim-mcp"] ["neovim"] (
          #   builtins.readFile (builtins.fetchurl {
          #     url = "https://raw.githubusercontent.com/paulburgess1357/nvim-mcp/89608e1fe6ea82a5e5f2da825934b726e6a97d4c/config/AGENTS-EXAMPLE.md";
          #     sha256 = "0609hz0v87vs487nqj23rcj28bmakndja25fvkai426bc92vprlv";
          #   })
          # );
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
    };
}
