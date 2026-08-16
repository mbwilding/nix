{
  lib,
  fetchFromGitHub,
  python314Packages,
}:

# nixpkgs tracks an older release; this pulls the latest tag directly from
# upstream instead. See update-custom-packages.sh's fetchFromGitHub-by-tag path.
python314Packages.buildPythonApplication rec {
  pname = "cfn-lint";
  version = "1.54.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "aws-cloudformation";
    repo = "cfn-lint";
    tag = "v${version}";
    hash = "sha256-8wQqk1pghdMF+CQuDnrBNRSvZBLmV0REZ7vNnAMjbDY=";
  };

  build-system = [ python314Packages.setuptools ];

  dependencies = with python314Packages; [
    jsonpatch
    networkx
    pyyaml
    regex
    sympy
    typing-extensions
  ];

  doCheck = false;

  pythonImportsCheck = [ "cfnlint" ];

  meta = {
    description = "Checks CloudFormation templates for practices and behaviour that could potentially be improved";
    homepage = "https://github.com/aws-cloudformation/cfn-lint";
    changelog = "https://github.com/aws-cloudformation/cfn-lint/blob/${src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "cfn-lint";
  };
}
