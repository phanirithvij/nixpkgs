{
  mkSbtDerivation,
  bbb-shared-utils,
  bbb-common-message,
}:

mkSbtDerivation {
  pname = "bbb-common-web";
  version = bbb-shared-utils.versionComponent;

  inherit (bbb-shared-utils) src;

  depsLockfile = ./deps.lock.json;

  inherit (bbb-shared-utils) postPatch;

  strictDeps = true;

  buildInputs = [ bbb-common-message ];

  buildPhase = ''
    runHook preBuild

    mkdir -p $HOME/.ivy2/local
    cp -r ${bbb-common-message}/* $HOME/.ivy2/local/
    chmod -R +w $HOME/.ivy2/local/

    cd bbb-common-web

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
    description = bbb-shared-utils.meta.description + " (bbb-common-web)";
  };
}
