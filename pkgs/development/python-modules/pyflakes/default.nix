{
  lib,
  buildPythonPackage,
  isPyPy,
  pythonAtLeast,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "pyflakes";
  version = "3.2.0";

  disabled = pythonOlder "3.8";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "PyCQA";
    repo = "pyflakes";
    rev = version;
    hash = "sha256-ouCkkm9OrYob00uLTilqgWsTWfHhzaiZp7sa2C5liqk=";
  };

  nativeBuildInputs = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "pyflakes" ];

  disabledTests =
    lib.optionals (pythonAtLeast "3.13") [
      # AssertionError: invalid syn[18 chars]
      # AssertionError: Expected one or more names after 'import'
      "test_errors_syntax"
    ]
    ++ lib.optionals (isPyPy && pythonAtLeast "3.10") [
      "test_eofSyntaxError"
      "test_misencodedFileUTF8"
      "test_multilineSyntaxError"
    ];

  meta = with lib; {
    homepage = "https://github.com/PyCQA/pyflakes";
    changelog = "https://github.com/PyCQA/pyflakes/blob/${src.rev}/NEWS.rst";
    description = "Simple program which checks Python source files for errors";
    mainProgram = "pyflakes";
    license = licenses.mit;
    maintainers = with maintainers; [ dotlambda ];
  };
}
