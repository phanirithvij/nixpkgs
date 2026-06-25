{
  lib,
  buildNpmPackage,
  makeWrapper,
  bbb-shared-utils,
  nodejs_22,
}:

buildNpmPackage {
  pname = "bbb-transcription-controller";
  version = bbb-shared-utils.versionComponent;

  src = "${bbb-shared-utils.src}/bbb-transcription-controller";

  npmDepsHash = "sha256-M9638fAfWHh3QiVYOmhVoOgDZKQ1Y322b3RQpFoSyp4=";

  dontNpmBuild = true;

  strictDeps = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/bbb-transcription-controller
    cp -r * $out/share/bbb-transcription-controller/

    makeWrapper ${lib.getExe nodejs_22} $out/bin/bbb-transcription-controller \
      --add-flags $out/share/bbb-transcription-controller/app.js

    runHook postInstall
  '';

  meta = bbb-shared-utils.meta // {
    description = bbb-shared-utils.meta.description + " (bbb-transcription-controller)";
  };
}
