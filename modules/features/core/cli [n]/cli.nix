{ inputs, ... }:

{
  flake.modules.homeManager.cli = {
    imports = with inputs.self.modules.homeManager; [
      # ghostty
      atuin
      aws
      btop
      dapr
      development
      direnv
      dotnet
      fastfetch
      files
      fzf
      gh
      git
      k9s
      lazygit
      lazysql
      mcp
      neovim
      opencode
      package-managers
      packages-cli
      proxy
      proxychains
      shells
      ssh
      yazi
      zellij
      zoxide
    ];
  };
}
