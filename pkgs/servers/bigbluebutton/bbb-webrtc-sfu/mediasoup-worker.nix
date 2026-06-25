{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  python3,
  pkg-config,
  nettools,
  cacert,
  doxygen,
  flatbuffers,
}:

let
  version = "3.14.14";

  src = fetchFromGitHub {
    owner = "versatica";
    repo = "mediasoup";
    rev = version;
    sha256 = "1y6fpsyl5dadj6qhzyh8558d4zlxlwa3lxjxp27zvc22i6yw1w8v";
  };

  # mediasoup-worker uses meson subprojects heavily.
  # We fetch them in a fixed-output derivation.
  subprojects = stdenv.mkDerivation {
    name = "mediasoup-worker-subprojects-${version}";
    inherit src;

    nativeBuildInputs = [
      meson
      python3
      ninja
      cacert
    ];

    phases = [
      "unpackPhase"
      "buildPhase"
      "installPhase"
    ];

    buildPhase = ''
      cd worker
      # Download all meson subprojects
      meson subprojects download
    '';

    installPhase = ''
      mkdir -p $out
      cp -r subprojects/* $out/
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-cmWIMgWqcZPkMsQfCJ3V6obb4erLbTsvFMOrAw0QirQ=";
  };

in
stdenv.mkDerivation {
  pname = "mediasoup-worker";
  inherit version src;

  nativeBuildInputs = [
    meson
    ninja
    python3
    pkg-config
    doxygen
    flatbuffers
  ];

  # Optional for testing or runtime?
  buildInputs = [ ];

  preConfigure = ''
    # Remove existing subprojects directory which only contains .wrap files
    rm -rf subprojects
    cp -r ${subprojects} subprojects
    chmod -R +w subprojects

    # Fix race condition in meson.build where flatbuffers_generator_dep doesn't actually depend on flatbuffers_generator
    sed -i "/include_directories: '.',/a \\  sources: flatbuffers_generator," fbs/meson.build

    # Fix GCC 15 build failure in abseil-cpp
    sed -i "1i #include <cstdint>" subprojects/abseil-cpp-20230802.1/absl/container/internal/container_memory.h

    # Do not build tests or fuzzer
    sed -i '/^test_sources = \[/,$d' meson.build
  '';

  # `meson.build` relies on the fact that we're in `worker`
  sourceRoot = "source/worker";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp mediasoup-worker $out/bin/

    runHook postInstall
  '';

  meta = {
    description = "Mediasoup worker binary";
    homepage = "https://mediasoup.org";
    license = lib.licenses.isc;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
