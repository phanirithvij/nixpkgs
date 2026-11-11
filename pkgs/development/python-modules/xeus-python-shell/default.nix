{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  debugpy,
  ipython,
}:

buildPythonPackage rec {
  pname = "xeus-python-shell";
  version = "0.8.1";
  pyproject = true;

  src = fetchPypi {
    pname = "xeus_python_shell";
    inherit version;
    hash = "sha256-lPYLriaPBsN1G7j3tQo8Hmh/HEfyjm8basyBAnQw8ZQ=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    debugpy
    ipython
  ];

  pythonImportsCheck = [
    "xeus_python_shell"
    "xeus_python_shell.shell"
  ];

  meta = {
    description = "The xeus-python core python logic";
    homepage = "https://github.com/jupyter-xeus/xeus-python-shell";
    changelog = "https://github.com/jupyter-xeus/xeus-python-shell/releases/tag/${version}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ phanirithvij ];
  };
}
