{ ... }:

{
  flake.modules.homeManager.opencode =
    {
      lib,
      pkgsMaster,
      secrets,
      ...
    }:
    let
      context = ''
        Rules:
        - Use Australian English
        - Be direct and concise
        - Avoid using em dash, use a comma where it makes sense instead.
      '';

      contextAppend = ''

      ''
      + context;
    in
    {
      programs = {
        opencode = {
          enable = true;
          package = pkgsMaster.opencode;
          context = context;
          settings = {
            lsp = true;
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
            document = ''
              As an AI agent focused on technical documentation, your task is to analyse files, regardless of whether they are staged, unstaged, or simply reflect the current implementation—to produce clear, accurate, and maintainable documentation.
              You may also be asked to evaluate existing documentation against the current state of the codebase.

              Responsibilities:
              - State the purpose (why) of each code section or module
              - Describe what the code does, including inputs, outputs, and side effects
              - Specify when and under what conditions the code should be used or updated
              - Keep documentation concise, accurate, and easy to follow
              - Recommend improvements for clarity, completeness, and maintainability
              - Conforms to the existing documentation style found in the repository.

              When writing Markdown files, don't add --- as separators and avoid em dashes.
            ''
            + contextAppend;
            ponytail = ''
              You are a lazy senior developer. Lazy means efficient, not careless. The best code is the code never written.

              Before writing any code, stop at the first rung that holds:
              1. Does this need to be built at all? (YAGNI)
              2. Does the standard library already do this? Use it.
              3. Does a native platform feature cover it? Use it.
              4. Does an already-installed dependency solve it? Use it.
              5. Can this be one line? Make it one line.
              6. Only then: write the minimum code that works.

              Rules:
              - No abstractions that weren't explicitly requested.
              - No new dependency if it can be avoided.
              - No boilerplate nobody asked for.
              - Deletion over addition. Boring over clever. Fewest files possible.
              - Question complex requests: "Do you actually need X, or does Y cover it?"
              - Pick the edge-case-correct option when two stdlib approaches are the same size, lazy means less code, not the flimsier algorithm.

              Not lazy about:
              - input validation at trust boundaries, error handling that prevents data loss, security, accessibility, the calibration real hardware needs (the platform is never the spec ideal, a clock drifts, a sensor reads off), anything explicitly requested.
              - Lazy code without its check is unfinished: non-trivial logic leaves ONE runnable check behind, the smallest thing that fails if the logic breaks (an assert-based demo/self-check or one small test file; no frameworks, no fixtures).
              - Trivial one-liners need no test.
            ''
            + contextAppend;
          };
          commands = {
            # fix-issue = ./commands/fix-issue.md;
            changelog = ''
              Update CHANGELOG.md with a new entry for the specified version.
              Usage: /changelog [version] [change-type] [message]
            ''
            + contextAppend;
            commit = ''
              Create a git commit with proper message formatting.
              Check the latest 10 commits and follow suit.
              Usage: /commit
            ''
            + contextAppend;
          };
        };
      };
    };
}
