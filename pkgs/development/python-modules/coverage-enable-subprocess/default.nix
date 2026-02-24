{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "coverage-enable-subprocess";
  version = "1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "bukzor";
    repo = "python-coverage-enable-subprocess";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YiFxss5M71hA0LE1ZAzP9RJnVzxOwp2lQheNhsZ4OsA=";
  };

  build-system = [
    setuptools
  ];

  pythonImportsCheck = [
    "coverage_enable_subprocess"
  ];

  meta = {
    description = "";
    homepage = "https://github.com/bukzor/python-coverage-enable-subprocess";
    # https://github.com/bukzor/python-coverage-enable-subprocess/blob/9a0f4df99f0d008eba305c673dfae4269c6c5642/setup.py#L129
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ phanirithvij ];
  };
})
