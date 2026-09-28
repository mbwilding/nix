{ vscode-extensions }:

{
  extension = vscode-extensions.rust-lang.rust-analyzer;

  settings = {
    "rust-analyzer.check.command" = "clippy";
  };
}
