{ ... }:

{
  programs = {
    opencode = {
      enable = true;
      enableMcpIntegration = true;
      agents = {
        code-reviewer = ''
          # Code Reviewer Agent

          You are a senior software engineer specializing in code reviews.
          Focus on code quality, security, and maintainability.

          ## Guidelines
          - Review for potential bugs and edge cases
          - Check for security vulnerabilities
          - Ensure code follows best practices
          - Suggest improvements for readability and performance
        '';
      };
      commands = {
        changelog = ''
          # Update Changelog Command

          Update CHANGELOG.md with a new entry for the specified version.
          Usage: /changelog [version] [change-type] [message]
        '';
        # fix-issue = ./commands/fix-issue.md;
        commit = ''
          # Commit Command

          Create a git commit with proper message formatting.
          Usage: /commit [message]
        '';
      };
    };
  };
}
