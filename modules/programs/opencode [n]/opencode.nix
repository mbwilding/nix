{ ... }:

{
  flake.modules.homeManager.opencode =
    { ... }:
    {
      programs = {
        opencode = {
          enable = true;
          enableMcpIntegration = true;
          context = builtins.readFile (builtins.fetchurl {
            url = "https://raw.githubusercontent.com/paulburgess1357/nvim-mcp/refs/heads/master/config/AGENTS-EXAMPLE.md";
            sha256 = "0fxg9f9mxmdgzwmyk2xqmc2fgvaa2v4dswhwzvdqpl0h27gw700k";
          });
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

              ## Jira

              ### Story Template

              ```markdown
              ## Overview

              {{ FEATURE_DESCRIPTION }}

              ## Story

              **As a** {{ PERSONA }}
              **I want** {{ GOAL }}
              **So that** {{ BENEFIT }}

              ## Acceptance Criteria

              {{ ACCEPTANCE_CRITERIA }}

              ## Key Technical Notes

              {{ KEY_TECHNICAL_NOTES }}
              ```

              ### Usage

              Read the Jira template from `.github/skills/create-feature-design/jira-story-template.md`.

              Replace all `{{ PLACEHOLDER }}` values, including the Confluence page URL and the shareable
              Lucid diagram URLs collected in Step 2.

              - `{{ ACCEPTANCE_CRITERIA }}` — copy the acceptance criteria bullet points from Step 1 verbatim
              - `{{ LUCID_DIAGRAMS_LIST }}` — one `- [label](url)` list item per collected diagram reference;
                if none, replace with `_No diagrams linked._`
              - `{{ KEY_TECHNICAL_NOTES }}` — a concise bullet list of the most important implementation
                constraints, any open questions flagged with ⚠️

              Use `Atlassian-createJiraIssue` with:
              - `projectKey` → from config
              - `issueTypeName` → from config (`Story`)
              - `summary` → the feature name
              - `description` → the filled-in Jira template
              - `contentFormat` → `"markdown"`

              Store the returned Jira issue `key` (e.g. `RDP-1234`) and `self` URL.

              ## How to Use This Agent

              Plan mode is used until the user has confirmed the plan, then we action.
              Ask questions using your built in question logic to ask for more info or if you don't understand something.

              If the user hasn't already provided the following, ask for them (all at once, not one by one):

              - **Feature name / title** – short name used as the page title and Jira summary
              - **Persona** – who is the user? (for the "As a..." story format)
              - **Goal** – what do they want to do?
              - **Benefit** – why do they want it? (the "So that..." clause)
              - **Background** – brief context on why this feature is needed
              - **Out of scope** – what is explicitly NOT part of this story?
              - **Acceptance criteria** – bullet points; can be refined later

              > **Scope discipline — do not invent functionality.**
              > Only include acceptance criteria, API endpoints, entities, and subtasks that are
              > **explicitly described by the user or directly implied by the stated acceptance criteria**.
              > Do not add "nice to have" features, list/search endpoints, notification flows, or admin
              > views unless the user has described them. If you are unsure whether something is in scope,
              > **ask** — do not assume and include it.
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
