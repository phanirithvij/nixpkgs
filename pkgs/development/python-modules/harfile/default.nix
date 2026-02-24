{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  pytest-codspeed,
  coverage,
  coverage-enable-subprocess,
  harfile,
  hypothesis,
  hypothesis-jsonschema,
  jsonschema,
  pytest,
}:

buildPythonPackage (finalAttrs: {
  pname = "harfile";
  version = "0.4.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "schemathesis";
    repo = "harfile";
    tag = "v${finalAttrs.version}";
    hash = "sha256-VjJOmNtBU39eKYiGJidivEZ3A77WWO45vypDcTG11Lg=";
  };

  build-system = [
    hatchling
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
      harfile
    ];
    tests = [
      coverage
      hypothesis
      hypothesis-jsonschema
      jsonschema
      pytest
    ];
  };

  pythonImportsCheck = [
    "harfile"
  ];

  meta = {
    description = "Writer for HTTP Archive (HAR) files";
    homepage = "https://github.com/schemathesis/harfile";
    changelog = "https://github.com/schemathesis/harfile/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ phanirithvij ];
  };
})
