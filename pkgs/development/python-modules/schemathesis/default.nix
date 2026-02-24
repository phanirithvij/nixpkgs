{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  click,
  colorama,
  harfile,
  httpx,
  hypothesis,
  hypothesis-graphql,
  hypothesis-jsonschema,
  jsonschema,
  jsonschema-rs,
  junit-xml,
  pyrate-limiter,
  pytest,
  pyyaml,
  requests,
  rich,
  starlette-testclient,
  tenacity,
  tomli,
  typing-extensions,
  werkzeug,
  pytest-codspeed,
  coverage,
  coverage-enable-subprocess,
  schemathesis,
  mkdocs-material,
  mkdocstrings,
  aiohttp,
  fastapi,
  flask,
  hypothesis-openapi,
  pydantic,
  pytest-asyncio,
  pytest-httpserver,
  pytest-mock,
  pytest-trio,
  pytest-xdist,
  strawberry-graphql,
  syrupy,
  tomli-w,
  trustme,
}:

buildPythonPackage (finalAttrs: {
  pname = "schemathesis";
  version = "4.10.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "schemathesis";
    repo = "schemathesis";
    tag = "v${finalAttrs.version}";
    hash = "sha256-O+NL7ZI5H8wL+1Sfj+6/wagel6WISEL91WoXnSxve1U=";
  };

  build-system = [
    hatchling
  ];

  dependencies = [
    click
    colorama
    harfile
    httpx
    hypothesis
    hypothesis-graphql
    hypothesis-jsonschema
    jsonschema
    jsonschema-rs
    junit-xml
    pyrate-limiter
    pytest
    pyyaml
    requests
    rich
    starlette-testclient
    tenacity
    tomli
    typing-extensions
    werkzeug
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
      schemathesis
    ];
    docs = [
      mkdocs-material
      mkdocstrings
    ];
    tests = [
      aiohttp
      coverage
      fastapi
      flask
      hypothesis-openapi
      pydantic
      pytest-asyncio
      pytest-httpserver
      pytest-mock
      pytest-trio
      pytest-xdist
      strawberry-graphql
      syrupy
      tomli-w
      trustme
    ];
  };

  pythonImportsCheck = [
    "schemathesis"
  ];

  meta = {
    description = "Catch API bugs before your users do";
    homepage = "https://github.com/schemathesis/schemathesis";
    changelog = "https://github.com/schemathesis/schemathesis/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ phanirithvij ];
  };
})
