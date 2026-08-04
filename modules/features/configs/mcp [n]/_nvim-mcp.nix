{ python3Packages }:

python3Packages.buildPythonApplication rec {
  pname = "nvim-mcp";
  version = "1.0.1";
  pyproject = true;

  src = python3Packages.fetchPypi {
    inherit version;
    pname = "nvim_mcp";
    hash = "sha256-zP9bruIwkjyfMX+AHslZ8gNN3p32IPkuWFyK8wUT7O0=";
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
