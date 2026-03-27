{ secrets, ... }:

{
  programs = {
    mcp = {
      enable = true;
      servers = {
        atlassian = {
          type = "http";
          url = "https://mcp.atlassian.com/v1/mcp";
          headers = {
            Authorization = "Bearer ${secrets.atlassianKey}";
          };
        };
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
          headers = {
            Authorization = "Bearer ${secrets.githubWorkToken}";
          };
        };
      };
    };
  };
}
