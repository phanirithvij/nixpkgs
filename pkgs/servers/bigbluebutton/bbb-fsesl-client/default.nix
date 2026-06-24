{
  mkSbtDerivation,
  bbb-shared-utils,
}:

mkSbtDerivation {
  pname = "bbb-fsesl-client";
  version = bbb-shared-utils.versionComponent;

  inherit (bbb-shared-utils) src postPatch;

  depsLockfile = ./deps.lock.json;

  strictDeps = true;

  buildPhase = ''
    runHook preBuild

    cd bbb-fsesl-client

    sbt publishLocal

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -t $out/ -r $HOME/.ivy2/local/*

    runHook postInstall
  '';

  meta = bbb-shared-utils.meta // {
    description = bbb-shared-utils.meta.description + " (bbb-fsesl-client)";
  };
}
