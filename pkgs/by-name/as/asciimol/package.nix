{
  fetchPypi,
  lib,
  python3Packages,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "asciimol";
  version = "1.2.7";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-SqwViOnVx1TcpY8Kd5VQCg1A8KQnBhL8aq9Gsrwer3k=";
  };

  build-system = with python3Packages; [ setuptools ];

  dependencies = with python3Packages; [
    numpy
    ase
    rdkit
  ];

  meta = {
    description = "Curses based ASCII molecule viewer for terminals";
    license = lib.licenses.bsd2;
    homepage = "https://github.com/dewberryants/asciimol";
    downloadPage = "https://pypi.org/project/asciimol/";
    maintainers = with lib.maintainers; [ tomasrivera ];
    mainProgram = "asciimol";
  };
})
