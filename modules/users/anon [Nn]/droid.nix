{ inputs, ... }:

{
  flake.modules.homeManager.droid =
    { secrets, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        atuin
        aws
        btop
        dapr
        direnv
        fzf
        git
        gh
        lazygit
        mcp
        npm
        opencode
        shells
        ssh
        yazi
        zoxide
      ];

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
