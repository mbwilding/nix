{ ... }:

{
  flake.modules.homeManager.mcp =
    { pkgs, secrets, ... }:

    let
      nvim-mcp = pkgs.callPackage ./_nvim-mcp.nix { };

      mcpServers = {
        github-work = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp";
          headers = {
            Authorization = "Bearer ${secrets.githubWorkToken}";
          };
        };
        github-personal = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp";
          headers = {
            Authorization = "Bearer ${secrets.githubPersonalToken}";
          };
        };
        gitlab = {
          type = "http";
          url = "https://gitlab.com/api/v4/mcp";
        };
        atlassian = {
          type = "http";
          url = "https://mcp.atlassian.com/v1/mcp";
        };
        lucid = {
          type = "http";
          url = "https://mcp.lucid.app/mcp";
        };
        # figma = {
        #   type = "http";
        #   url = "https://mcp.figma.com/mcp";
        # };
        neovim = {
          type = "stdio";
          command = "${nvim-mcp}/bin/nvim-mcp";
        };
      };
    in
    {
      programs.mcp = {
        enable = true;
        servers = mcpServers;
      };

      home.file.".copilot/mcp-config.json".text = builtins.toJSON { mcpServers = mcpServers; };
    };
}
