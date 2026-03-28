{ lib, secrets, ... }:

let
  base64 = import ../helpers/base64.nix { inherit lib; };
  atlassian = base64.toBase64 "${secrets.workEmailId}:${secrets.atlassianKey}";
in
{
  programs = {
    mcp = {
      enable = true;
      servers = {
        github-work = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
          headers = {
            Authorization = "Bearer ${secrets.githubWorkToken}";
          };
        };
        github-personal = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
          headers = {
            Authorization = "Bearer ${secrets.githubPersonalToken}";
          };
        };
        # atlassian = {
        #   type = "http";
        #   url = "https://mcp.atlassian.com/v1/mcp";
        #   headers = {
        #     Authorization = "Basic ${atlassian}";
        #   };
        # };
        # lucid = {
        #   type = "http";
        #   url = "https://mcp.lucid.app/mcp";
        #   headers = {
        #     Authorization = "Bearer ${secrets.lucidKey}";
        #   };
        # };
      };
    };
  };
}
