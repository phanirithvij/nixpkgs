{
  lib,
  stdenv,
  buildNpmPackage,
  bbb-shared-utils,
}:

buildNpmPackage {
  pname = "bbb-learning-dashboard";
  version = bbb-shared-utils.versionComponent;

  src = stdenv.mkDerivation {
    name = "bbb-learning-dashboard-patched-src";
    src = "${bbb-shared-utils.src}/bbb-learning-dashboard";
    installPhase = ''
      cp -r . $out
      cp ${./package-lock.json} $out/package-lock.json
    '';
  };

  npmDepsHash = "sha256-ecbQ4CIEBzbgcxjNQgaXYSrHHE0m5fsDo37Evwf9tNg=";

  npmFlags = [ "--legacy-peer-deps" ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/bbb-learning-dashboard
    cp -r build/* $out/share/bbb-learning-dashboard/

    runHook postInstall
  '';

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  meta = bbb-shared-utils.meta // {
    description = bbb-shared-utils.meta.description + " (bbb-learning-dashboard)";
  };
}
