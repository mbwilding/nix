{ lib, secrets, ... }:

let
  base64 = import ../helpers/base64.nix { inherit lib; };
  atlassian = base64.toBase64 "${secrets.workEmailId}:${secrets.atlassianRovo}";
in
{
  programs = {
    mcp = {
      enable = true;
      servers = {
        atlassian = {
          type = "http";
          url = "https://mcp.atlassian.com/v1/mcp";
          headers = {
            Authorization = "Basic ${atlassian}";
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
