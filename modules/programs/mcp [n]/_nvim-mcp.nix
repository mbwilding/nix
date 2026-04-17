{ python3Packages }:

python3Packages.buildPythonApplication rec {
  pname = "nvim-mcp";
  version = "0.6.1";
  pyproject = true;

  src = python3Packages.fetchPypi {
    inherit version;
    pname = "nvim_mcp";
    hash = "sha256-7AwOAQMThIuz6d6/VeiL2p1M0Je3qmsSgLmhuWXWb0Y=";
  };

  build-system = [ python3Packages.hatchling ];

  dependencies = with python3Packages; [
    mcp
    msgpack
    python-dotenv
    typer
  ];

  meta = {
    description = "MCP server for AI-assisted control of Neovim via msgpack-RPC";
    homepage = "https://github.com/paulburgess1357/nvim-mcp";
    mainProgram = "nvim-mcp";
  };
}
