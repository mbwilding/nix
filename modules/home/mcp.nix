{ secrets, ... }:

{
  programs = {
    mcp = {
      enable = true;
      servers = {
        atlassian = {
          url = "https://api.atlassian.com";
          headers = {
            ATLASSIAN_API_TOKEN = secrets.atlassianKey;
          };
        };
        github = {
          url = "https://api.github.com";
          headers = {
            GITHUB_TOKEN = secrets.githubWorkToken;
          };
        };
      };
    };
  };
}
