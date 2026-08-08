{ inputs, ... }:

{
  flake.modules.homeManager.user-droid =
    { secrets, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        atuin
        aws
        btop
        dapr
        direnv
        fzf
        gh
        git
        lazygit
        # opencode
        shells
        ssh
        yazi
        zoxide
      ];

      programs.mcp = {
        enable = true;
        servers.github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp";
          headers = {
            Authorization = "Bearer ${secrets.githubPersonalToken}";
          };
        };
      };

      home = {
        username = "nix-on-droid";
        homeDirectory = "/data/data/com.termux.nix/files/home";
        stateVersion = "24.05";

        sessionVariables = {
          EDITOR = "nvim";
          MANPAGER = "nvim +Man!";
          MANWIDTH = "999";
          RUST_LOG = "info";
        };

        packages = [ ];
      };
    };
}
