{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,

  # build-time
  qt5,

  # build-system
  setuptools,

  # dependencies
  datalab-capsule,
  fastapi,
  guidata,
  jedi,
  numpy,
  packaging,
  pandas,
  pip,
  plotpy,
  psutil,
  pydantic,
  pywavelets,
  scikit-image,
  scipy,
  sigima,
  sigimax,
  uvicorn,

  # optional-dependencies
  babel,
  build,
  coverage,
  pre-commit,
  pylint,
  ruff,
  myst-parser,
  pydata-sphinx-theme,
  sphinx,
  sphinx-copybutton,
  sphinx-design,
  sphinx-intl,
  sphinx-sitemap,
  sphinxcontrib-svg2pdfconverter,
  sphinxext-opengraph,
  opencv-python-headless,
  pyinstaller,
  pyqt5,
  httpx,
  pytest,
  pytest-xvfb,

  # tests
  pytestCheckHook,
  pyyaml,
  versionCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "datalab-platform";
  version = "1.4.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "DataLab-Platform";
    repo = "DataLab";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wTKo59eat2ZPtmfCf+gLW+4UA602Cn4iqshmlFGY+K8=";
  };

  # NOTE: DataLab is compatible with qt6, but it's apparently not perfect as
  # the executable segfaults on startup. For now, let's use qt5 which works and
  # migrate in the future.
  nativeBuildInputs = [
    qt5.wrapQtAppsHook
  ];

  buildInputs = [
    qt5.qtbase
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    qt5.qtwayland
  ];

  build-system = [
    setuptools
  ];

  dependencies = [
    datalab-capsule
    fastapi
    guidata
    jedi
    numpy
    packaging
    pandas
    pip
    plotpy
    psutil
    pydantic
    pywavelets
    scikit-image
    scipy
    sigima
    sigimax
    uvicorn
  ]
  ++ finalAttrs.passthru.optional-dependencies.qt
  # required for `bin/datalab-{demo,tests}`
  ++ finalAttrs.passthru.optional-dependencies.test;

  optional-dependencies = {
    dev = [
      babel
      build
      coverage
      pre-commit
      pylint
      ruff
    ];
    doc = [
      myst-parser
      pydata-sphinx-theme
      sphinx
      sphinx-copybutton
      sphinx-design
      sphinx-intl
      sphinx-sitemap
      sphinxcontrib-svg2pdfconverter
      sphinxext-opengraph
    ];
    exe = [
      opencv-python-headless
      pyinstaller
      pyqt5
    ];
    opencv = [
      opencv-python-headless
    ];
    qt = [
      pyqt5
    ];
    test = [
      httpx
      pytest
      pytest-xvfb
    ];
  };

  pythonImportsCheck = [
    "datalab"
  ];

  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  doInstallCheck = true;

  nativeCheckInputs = [
    pytestCheckHook
    pyyaml
  ]
  ++ finalAttrs.passthru.optional-dependencies.test;

  pytestFlags = [
    "--collect-only"
  ];

  dontWrapQtApps = true;

  preFixup = ''
    # Python scripts need to be manually wrapped
    for exe in "$out/bin"/datalab*; do
      wrapQtApp "$exe"
    done
  '';

  meta = {
    description = "Open-source Platform for Scientific and Technical Data Processing and Visualization";
    homepage = "https://github.com/DataLab-Platform/DataLab";
    changelog = "https://github.com/DataLab-Platform/DataLab/releases/tag/${finalAttrs.src.tag}";
    mainProgram = "datalab";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ eljamm ];
    teams = with lib.teams; [ ngi ];
  };
})
