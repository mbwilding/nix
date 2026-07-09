{ ... }:

{
  flake.modules.homeManager.claudecode =
    {
      pkgsMaster,
      ...
    }:
    {
      programs = {
        claude-code = {
          enable = true;
          package = pkgsMaster.claude-code;
          context = ../context.md;
          settings = {
            includeCoAuthoredBy = false;
            model = "claude-sonnet-5";
          };
          agents = {
            ponytail = ../agent-ponytail.md;
          };
          commands = {
            commit = ../command-commit.md;
            doco = ../command-doco.md;
          };
        };
      };
    };
}
