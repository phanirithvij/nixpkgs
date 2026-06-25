{
  lib,
  bbb-shared-utils,
  buildNpmPackage,
}:

buildNpmPackage {
  pname = "bbb-html5";
  version = bbb-shared-utils.versionComponent;
  src = "${bbb-shared-utils.src}/bigbluebutton-html5";

  npmDepsHash = "sha256-FtciHexUj8mGaM4ou+0o/ROornQHIiAOlI/luvMKEHE=";

  # We just want to build it and output dist
  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/bigbluebutton/html5-client
    cp -r dist/* $out/share/bigbluebutton/html5-client/

    runHook postInstall
  '';

  meta = bbb-shared-utils.meta // {
    description = "BigBlueButton HTML5 Client";
  };
}
