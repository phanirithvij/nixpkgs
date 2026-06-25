{
  lib,
  stdenv,
  bbb-shared-utils,
}:

stdenv.mkDerivation {
  pname = "bbb-playback";
  version = bbb-shared-utils.versionComponent;

  src = "${bbb-shared-utils.src}/record-and-playback";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/bbb-playback
    cp -r * $out/share/bbb-playback/

    runHook postInstall
  '';

  meta = bbb-shared-utils.meta // {
    description = bbb-shared-utils.meta.description + " (bbb-playback scripts and assets)";
  };
}
