{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  requests,
  starlette,
}:

buildPythonPackage (finalAttrs: {
  pname = "starlette-testclient";
  version = "0.4.1-unstable-2024-04-29";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Kludex";
    repo = "starlette-testclient";
    rev = "f8015878f4c35aac25cc325eb9b1cec5728b555c";
    hash = "sha256-zj92srCZK2M+9iqPzRpYLTb8vG0552q48HetLScceGA=";
  };

  build-system = [
    hatchling
  ];

  dependencies = [
    requests
    starlette
  ];

  pythonImportsCheck = [
    "starlette_testclient"
  ];

  meta = {
    description = "A backport of Starlette's TestClient using requests";
    homepage = "https://github.com/Kludex/starlette-testclient";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ phanirithvij ];
  };
})
