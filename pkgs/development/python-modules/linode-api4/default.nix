{
  lib,
  buildPythonPackage,
  deprecated,
  fetchFromGitHub,
  httpretty,
  mock,
  polling,
  pyprojectVersionPatchHook,
  pytestCheckHook,
  requests,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "linode-api4";
  version = "5.49.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "linode";
    repo = "linode_api4-python";
    tag = "v${finalAttrs.version}";
    hash = "sha256-VQ8G9ouuvrGR3CqjuA84xjo80f8k84a/LsXPDoi4V6M=";
  };

  build-system = [ setuptools ];

  nativeBuildInputs = [ pyprojectVersionPatchHook ];

  dependencies = [
    deprecated
    polling
    requests
  ];

  nativeCheckInputs = [
    httpretty
    mock
    pytestCheckHook
  ];

  pythonImportsCheck = [ "linode_api4" ];

  disabledTestPaths = [
    # Tests require an API token
    "test/integration/"
  ];

  meta = {
    description = "Official Python bindings for the Linode API";
    homepage = "https://github.com/linode/linode_api4-python";
    changelog = "https://github.com/linode/linode_api4-python/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ fab ];
  };
})
