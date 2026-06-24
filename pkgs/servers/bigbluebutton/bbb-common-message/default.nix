{
  mkSbtDerivation,
  bbb-shared-utils,
}:

mkSbtDerivation {
  pname = "bbb-common-message";
  version = bbb-shared-utils.versionComponent;

  inherit (bbb-shared-utils) src;

  depsLockfile = ./deps.lock.json;

  inherit (bbb-shared-utils) postPatch;

  strictDeps = true;

  buildPhase = ''
    runHook preBuild

    cd bbb-common-message

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
    description = bbb-shared-utils.meta.description + " (bbb-common-message)";
  };
}
