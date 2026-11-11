{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  xeus,
  xeus-zmq,
  pybind11_json,
  python3,
  zeromq,
  cppzmq,
  nlohmann_json,
  xtl,
  libuuid,
  openssl,
  makeWrapper,
  boost,
  doctest,
  versionCheckHook,
}:

let
  pythonEnv = python3.withPackages (ps: [
    ps.xeus-python-shell
  ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "xeus-python";
  version = "0.19.1";

  src = fetchFromGitHub {
    owner = "jupyter-xeus";
    repo = "xeus-python";
    tag = finalAttrs.version;
    hash = "sha256-LBDHk+rWgWuqhlwwsraodaKaKtS2tvSqpieSzYwi1+0=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    xeus
    xeus-zmq
    pybind11_json
    python3
    python3.pkgs.pybind11
    zeromq
    cppzmq
    nlohmann_json
    xtl
    libuuid
    openssl
  ];

  cmakeFlags = [
    "-DXEUS_PYTHONHOME_ABSPATH=${pythonEnv}"
    (lib.cmakeBool "XPYT_BUILD_TESTS" finalAttrs.doCheck)
  ];

  nativeCheckInputs = [
    doctest
  ];

  checkInputs = [
    boost
  ];

  doCheck = true;

  checkTarget = "xtest";

  preCheck = ''
    export PATH="$PWD:$PATH"
    export PYTHONHOME="${pythonEnv}"
    export PYTHON_EXECUTABLE="${pythonEnv}/bin/python3"
  '';

  postInstall = ''
    wrapProgram $out/bin/xpython \
      --set-default PYTHONHOME "${pythonEnv}" \
      --set-default PYTHON_EXECUTABLE "${pythonEnv}/bin/python3"
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  doInstallCheck = true;

  meta = {
    description = "Jupyter kernel for the Python programming language based on xeus";
    homepage = "https://github.com/jupyter-xeus/xeus-python";
    changelog = "https://github.com/jupyter-xeus/xeus-python/releases/tag/${finalAttrs.version}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ phanirithvij ];
    mainProgram = "xpython";
    platforms = lib.platforms.all;
  };
})
