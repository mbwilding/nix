{ ... }:

{
  flake.modules.homeManager.npm = { ... }: {
    imports = [
      ./_gh-actions-language-server.nix
    ];
  };
}
