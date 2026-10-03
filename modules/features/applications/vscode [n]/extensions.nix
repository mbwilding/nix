{ inputs, ... }:

{
  flake.modules.homeManager.vscode =
    { pkgs, ... }:

    {
      programs.vscode.profiles.default.extensions =
        with pkgs.vscode-extensions;
        [
          eamodio.gitlens
          usernamehw.errorlens
          vadimcn.vscode-lldb
          dbaeumer.vscode-eslint
          anthropic.claude-code
        ]
        ++ [ inputs.gronk.packages.${pkgs.stdenv.hostPlatform.system}.gronk-vscode ];
    };
}
