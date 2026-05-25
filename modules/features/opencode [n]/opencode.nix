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

              You are a senior software engineer specializing in writing and reviewing technical documentation.
              Focus on explaining the *why*, *what*, and *when* behind code and design decisions.

              Check the staged/unstaged files.

              ## Guidelines
              - Clearly articulate the purpose (*why*) of code sections and modules
              - Describe *what* the code does, including its inputs, outputs, and side effects
              - Specify *when* and under what conditions the code should be used or modified
              - Ensure documentation is concise, accurate, and easy to understand
              - Suggest improvements for clarity, completeness, and maintainability
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
