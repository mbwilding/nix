{ ... }:

{
  flake.modules.homeManager.opencode =
    { ... }:
    {
      programs = {
        opencode = {
          enable = true;
          enableMcpIntegration = true;
          # context = builtins.replaceStrings ["nvim-mcp"] ["neovim"] (
          #   builtins.readFile (builtins.fetchurl {
          #     url = "https://raw.githubusercontent.com/paulburgess1357/nvim-mcp/89608e1fe6ea82a5e5f2da825934b726e6a97d4c/config/AGENTS-EXAMPLE.md";
          #     sha256 = "0609hz0v87vs487nqj23rcj28bmakndja25fvkai426bc92vprlv";
          #   })
          # );
          agents = {
            code-reviewer = ''
              # Code Reviewer Agent

              You are a senior software engineer specialising in code reviews.
              Focus on code quality, security, and maintainability.

              ## Guidelines
              - Review for potential bugs and edge cases
              - Check for security vulnerabilities
              - Ensure code follows best practices
              - Suggest improvements for readability and performance
              - Make sure all outputs are in Australian English spelling
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
              Usage: /commit [message]
            '';
          };
        };
      };
    };
}
