{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  setuptools,

  # optional-dependencies
  dill,
  flask,
  graphviz,
  multiprocess,
  regex,
  requests,
  sphinx,
  sphinx-click,

  # tests
  pytestCheckHook,
  ddt,
  cryptography,
  python-dateutil,
  pytest,
  httpx,
  mongomock,
  pymongo,
  testcontainers,
  pymysql,
  numpy,
  pymoo,
  schemathesis,
}:

buildPythonPackage (finalAttrs: {
  pname = "schedula";
  version = "1.6.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "vinci1it2000";
    repo = "schedula";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zddn3Z26UrCxMKx3kvYHLMj9Ye7QvaOpzdCZVfcQdbA=";
  };

  build-system = [ setuptools ];

  optional-dependencies = {
    # dev omitted, we have nativeCheckInputs for this
    # form omitted, as it pulls in a kitchensink of deps, some not even packaged in nixpkgs
    io = [ dill ];
    parallel = [ multiprocess ];
    plot = [
      requests
      graphviz
      regex
      flask
    ];
    sphinx = [
      sphinx
      sphinx-click
    ]
    ++ finalAttrs.passthru.optional-dependencies.plot;
    web = [
      requests
      regex
      flask
    ];
  };

  nativeCheckInputs = [
    pytestCheckHook
  ];

  checkInputs = [
    #sphinx
    ddt
    #coveralls
    cryptography # doctests
    python-dateutil
    setuptools
    pytest
    httpx
    mongomock
    pymongo
    testcontainers
    pymysql
    numpy
    pymoo
    schemathesis
  ]
  ++ finalAttrs.passthru.optional-dependencies.io
  ++ finalAttrs.passthru.optional-dependencies.parallel
  ++ finalAttrs.passthru.optional-dependencies.plot;

  disabledTests = [
    # FAILED tests/test_setup.py::TestSetup::test_long_description - ModuleNotFoundError: No module named 'sphinxcontrib.writers'
    "test_long_description"
  ];

  disabledTestPaths = [
    # ERROR tests/utils/test_form.py::TestDispatcherForm::test_form1 - ModuleNotFoundError: No module named 'chromedriver_autoinstaller'
    # ERROR tests/utils/test_form.py::TestDispatcherForm::test_form_stripe - ModuleNotFoundError: No module named 'chromedriver_autoinstaller'
    "tests/utils/test_form.py"
  ];

  pythonImportsCheck = [ "schedula" ];

  meta = {
    description = "Smart function scheduler for dynamic flow-based programming";
    homepage = "https://github.com/vinci1it2000/schedula";
    changelog = "https://github.com/vinci1it2000/schedula/blob/${finalAttrs.src.tag}/CHANGELOG.rst";
    license = lib.licenses.eupl11;
    maintainers = with lib.maintainers; [ flokli ];
    # at least some tests fail on Darwin
    platforms = lib.platforms.linux;
  };
})
