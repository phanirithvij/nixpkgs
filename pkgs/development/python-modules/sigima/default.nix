{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  setuptools,

  # dependencies
  guidata,
  imagecodecs,
  makefun,
  numpy,
  packaging,
  pandas,
  pywavelets,
  scikit-image,
  scipy,

  # optional-dependencies
  babel,
  build,
  coverage,
  jsonschema,
  pre-commit,
  pylint,
  ruff,
  wheel,
  matplotlib,
  myst-nb,
  myst-parser,
  opencv-python-headless,
  plotpy,
  pydata-sphinx-theme,
  pyqt5,
  qtpy,
  sphinx,
  sphinx-copybutton,
  sphinx-design,
  sphinx-gallery,
  sphinx-intl,
  pytest,
  pytest-xvfb,

  # tests
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "sigima";
  version = "1.4.0";
  pyproject = true;
  __darwinAllowLocalNetworking = true;

  src = fetchFromGitHub {
    owner = "DataLab-Platform";
    repo = "Sigima";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NDbRZFPdlgu7+TzTwFO0zYYZDN54Ce58l8KbH3C9ZcY=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    guidata
    imagecodecs
    makefun
    numpy
    packaging
    pandas
    pywavelets
    scikit-image
    scipy
  ];

  optional-dependencies = {
    dev = [
      babel
      build
      coverage
      pre-commit
      pylint
      ruff
      setuptools
      wheel
    ];
    doc = [
      matplotlib
      myst-nb
      myst-parser
      opencv-python-headless
      plotpy
      pydata-sphinx-theme
      pyqt5
      qtpy
      sphinx
      sphinx-copybutton
      sphinx-design
      sphinx-gallery
      sphinx-intl
    ];
    opencv = [
      opencv-python-headless
    ];
    qt = [
      plotpy
      pyqt5
      qtpy
    ];
    test = [
      jsonschema
      pytest
      pytest-xvfb
    ];
  };

  nativeCheckInputs = [
    pytestCheckHook
  ]
  ++ finalAttrs.passthru.optional-dependencies.test;

  disabledTests = [
    # imagecodecs in nixpkgs is built without ccittfax4
    "test_read_ccitt_group4_tiff"
  ];

  pythonImportsCheck = [
    "sigima"
  ];

  meta = {
    description = "Scientific computing engine for 1D signals and 2D images";
    homepage = "https://github.com/DataLab-Platform/Sigima";
    changelog = "https://github.com/DataLab-Platform/Sigima/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ eljamm ];
    teams = with lib.teams; [ ngi ];
  };
})
