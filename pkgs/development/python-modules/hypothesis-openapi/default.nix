{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  hypothesis,
  pytest-codspeed,
  coverage,
  coverage-enable-subprocess,
  hypothesis-openapi,
  jsonschema,
  pytest,
  pytest-xdist,
  referencing,
}:

buildPythonPackage (finalAttrs: {
  pname = "hypothesis-openapi";
  version = "0.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Stranger6667";
    repo = "hypothesis-openapi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ihgGgFCbHnPpmT02yimcG3c9WhuAfM5vyCWSLe8DLO4=";
  };

  build-system = [
    hatchling
  ];

  dependencies = [
    hypothesis
  ];

  optional-dependencies = {
    bench = [
      pytest-codspeed
    ];
    cov = [
      coverage
      coverage-enable-subprocess
    ];
    dev = [
      hypothesis-openapi
    ];
    tests = [
      coverage
      jsonschema
      pytest
      pytest-xdist
      referencing
    ];
  };

  pythonImportsCheck = [
    "hypothesis_openapi"
  ];

  meta = {
    description = "Hypothesis plugin for generating valid Open API documents";
    homepage = "https://github.com/Stranger6667/hypothesis-openapi";
    changelog = "https://github.com/Stranger6667/hypothesis-openapi/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ phanirithvij ];
  };
})
