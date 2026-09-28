{ ... }:

{
  flake.modules.homeManager.vscode =
    { pkgs, ... }:

    {
      programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
        eamodio.gitlens
        usernamehw.errorlens
        vadimcn.vscode-lldb
        dbaeumer.vscode-eslint
        anthropic.claude-code
      ];
    };
}
