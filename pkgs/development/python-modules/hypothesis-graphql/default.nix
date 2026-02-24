{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  graphql-core,
  hypothesis,
  coverage,
  coverage-enable-subprocess,
  hypothesis-graphql,
  pytest,
  pytest-xdist,
}:

buildPythonPackage (finalAttrs: {
  pname = "hypothesis-graphql";
  version = "0.12.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Stranger6667";
    repo = "hypothesis-graphql";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dncDIeD0n2quwDm9D6w5JX7zSV0cifTfVvmqjNN0xP0=";
  };

  build-system = [
    hatchling
  ];

  dependencies = [
    graphql-core
    hypothesis
  ];

  optional-dependencies = {
    cov = [
      coverage
      coverage-enable-subprocess
    ];
    dev = [
      hypothesis-graphql
    ];
    tests = [
      coverage
      pytest
      pytest-xdist
    ];
  };

  pythonImportsCheck = [
    "hypothesis_graphql"
  ];

  meta = {
    description = "Generate arbitrary queries matching your GraphQL schema, and use them to verify your backend implementation";
    homepage = "https://github.com/Stranger6667/hypothesis-graphql";
    changelog = "https://github.com/Stranger6667/hypothesis-graphql/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ phanirithvij ];
  };
})
