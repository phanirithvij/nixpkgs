{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  cython,
  setuptools,

  # dependencies
  guidata,
  numpy,
  pillow,
  pythonqwt,
  scikit-image,
  scipy,
  tifffile,

  # tests
  pytestCheckHook,
  qt6,
  pyqt6,

  pkgs, # for passthru.tests
}:

buildPythonPackage rec {
  pname = "plotpy";
  version = "2.7.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "PlotPyStack";
    repo = "PlotPy";
    tag = "v${version}";
    hash = "sha256-FmSFcCAJZyzD9qRE+L2oxWtyh2spJSLRq+xtx4e1Rhg=";
  };

  build-system = [
    cython
    setuptools
  ];

  dependencies = [
    guidata
    numpy
    pillow
    pythonqwt
    scikit-image
    scipy
    tifffile
  ];

  nativeCheckInputs = [
    pytestCheckHook
    # Not propagating this, to allow one to choose to choose a pyqt / pyside
    # implementation.
    pyqt6
  ];

  preCheck = ''
    export QT_PLUGIN_PATH="${lib.getBin qt6.qtbase}/${qt6.qtbase.qtPluginPrefix}"
    export QT_QPA_PLATFORM=offscreen
    # https://github.com/NixOS/nixpkgs/issues/255262
    cd $out
  '';

  disabledTests = lib.optionals stdenv.hostPlatform.isDarwin [
    # Fatal Python error: Segmentation fault
    # in plotpy/widgets/resizedialog.py", line 99 in __init__
    "test_resize_dialog"
    "test_tool"
  ];

  pythonImportsCheck = [
    "plotpy"
    "plotpy.tests"
  ];

  passthru = {
    tests = {
      withPyQt6 = pkgs.plotpy.override {
        inherit (pkgs)
          pyqt6
          qt6
          ;
      };
      withPyQt5 = pkgs.plotpy.override {
        pyqt6 = pkgs.pyqt5;
        qt6 = pkgs.qt5;
      };
    };
    # Upstream doesn't officially supports all of them, although they use
    # qtpy, see: https://github.com/PlotPyStack/PlotPy/issues/20
    knownFailingTests = {
      # Was failing with a peculiar segmentation fault during the tests, since
      # this package was added to Nixpkgs. This is not too bad as PySide2
      # shouldn't be used for modern applications.
      withPySide2 = pkgs.plotpy.override {
        pyqt6 = pkgs.pyside2;
        qt6 = pkgs.qt5;
      };
      # Has started failing too similarly to pyside2, ever since a certain
      # version bump. See also:
      # https://github.com/PlotPyStack/PlotPy/blob/v2.7.4/README.md?plain=1#L62
      withPySide6 = pkgs.plotpy.override {
        pyqt6 = pkgs.pyside6;
        qt6 = qt6;
      };
    };
  };

  meta = {
    description = "Curve and image plotting tools for Python/Qt applications";
    homepage = "https://github.com/PlotPyStack/PlotPy";
    changelog = "https://github.com/PlotPyStack/PlotPy/blob/${src.tag}/CHANGELOG.md";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ doronbehar ];
  };
}
