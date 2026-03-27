{ ... }:

{
  programs = {
    mcp = {
      enable = true;
      servers = {
        atlassian = {
          url = "https://api.atlassian.com";
          headers = {
            ATLASSIAN_API_TOKEN = "{env:ATLASSIAN_API_TOKEN}";
          };
        };
        github = {
          url = "https://api.github.com";
          headers = {
            GITHUB_TOKEN = "{env:GITHUB_TOKEN}";
          };
        };
      };
    };
  };
}
