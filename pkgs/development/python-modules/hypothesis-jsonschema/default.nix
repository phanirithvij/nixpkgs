{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "hypothesis-jsonschema";
  version = "0.23.1-unstable-2025-12-05";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "python-jsonschema";
    repo = "hypothesis-jsonschema";
    rev = "fa38b03d8bb6f917ba749ef84ce1e4465d1e27cc";
    hash = "sha256-gZH+3PaoDE+l6Q/aXG9PzjzsqG5oCmZlTVGtl5HPc4w=";
  };

  build-system = [
    setuptools
  ];

  pythonImportsCheck = [
    "hypothesis_jsonschema"
  ];

  meta = {
    description = "Tools to generate test data from JSON schemata with Hypothesis";
    homepage = "https://github.com/python-jsonschema/hypothesis-jsonschema";
    changelog = "https://github.com/python-jsonschema/hypothesis-jsonschema/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mpl20;
    maintainers = with lib.maintainers; [ phanirithvij ];
  };
})
