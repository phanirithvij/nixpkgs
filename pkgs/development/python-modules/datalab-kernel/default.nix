{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  h5py,
  httpx,
  matplotlib,
  numpy,
  sigima,
  xeus-python-shell,
  xeus-python,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "datalab-kernel";
  version = "0.2.12";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "DataLab-Platform";
    repo = "DataLab-Kernel";
    tag = "v${version}";
    hash = "sha256-w1h9//TxQ+4SvgcljO/KALoWO7VafAkPgdTsI4DSraw=";
  };

  build-system = [
    setuptools
  ];

  pythonRemoveDeps = [
    "xeus-python"
  ];

  dependencies = [
    h5py
    httpx
    matplotlib
    numpy
    sigima
    xeus-python-shell
    xeus-python
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  pytestFlags = [
    "datalab_kernel/tests/unit"
    "datalab_kernel/tests/contract"
  ];

  pythonImportsCheck = [
    "datalab_kernel"
  ];

  meta = {
    description = "Standalone Xeus-Python-based Jupyter kernel for DataLab with optional live synchronization";
    homepage = "https://github.com/DataLab-Platform/DataLab-Kernel";
    changelog = "https://github.com/DataLab-Platform/DataLab-Kernel/releases/tag/v${version}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ phanirithvij ];
    mainProgram = "datalab-kernel-install";
  };
}
