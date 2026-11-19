{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  pydantic,
  python-dateutil,
  requests,
  stackit-core,
}:

buildPythonPackage (finalAttrs: {
  pname = "stackit-iaas";
  version = "1.6.0";
  pyproject = true;

  src = fetchPypi {
    pname = "stackit_iaas";
    inherit (finalAttrs) version;
    hash = "sha256-E3qmdQnVagEGHwKJYt1ViAWp4SO81a6tc4qXiqE0uXU=";
  };

  build-system = [ hatchling ];

  dependencies = [
    pydantic
    python-dateutil
    requests
    stackit-core
  ];

  pythonImportsCheck = [ "stackit.iaas" ];

  # Module has no tests
  doCheck = false;

  meta = {
    description = "STACKIT IaaS API client for Python";
    homepage = "https://github.com/stackitcloud/stackit-sdk-python";
    changelog = "https://github.com/stackitcloud/stackit-sdk-python/blob/services/iaas/v${finalAttrs.version}/services/iaas/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ fab ];
  };
})
