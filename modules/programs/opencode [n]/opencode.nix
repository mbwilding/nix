{ ... }:

{
  flake.modules.homeManager.opencode =
    { ... }:
    {
      programs = {
        opencode = {
          enable = true;
          enableMcpIntegration = true;
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
            story-writer = ''
              # Story Writer Agent

              ## Local MCP Servers:

              - github-work
              - atlassian

              ## Agent

              https://github.com/rwwa/racing-wa/blob/spike/ai/.github/agents/feature-design.agent.md

              ## Skill

              https://github.com/rwwa/racing-wa/blob/spike/ai/.github/skills/create-feature-design/SKILL.md

              ## How to Use This Agent

              Plan mode is used until the user has confirmed the plan, then we action.

              Use the agent `feature-design.agent.md` as your additional system prompt.

              Use the `create-feature-design/Skill.md` skill to carry out the full creation workflow. The skill
              contains detailed step-by-step instructions.

              Ask questions using your built in question logic to ask for more info or if you don't understand something.

              You may also be invoked directly with a prompt like:
              - "Create a feature design for [feature description]"
              - "Design the [feature name] story"
              - "Create a new story for [feature]"
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
