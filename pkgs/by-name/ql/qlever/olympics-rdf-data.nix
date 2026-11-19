{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "qlever-olympics-rdf-data";
  version = "0-unstable-2019-01-22";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchurl {
    url = "https://github.com/wallscope/olympics-rdf/raw/54483d539082641d48e1d49873662b3af628ca4d/data/olympics-nt-nodup.zip";
    hash = "sha256-dY28CQKaMDUUw/pw+p9yX0EtJOnbAAplodMFaedL1B8=";
  };

  nativeBuildInputs = [
    unzip
  ];

  sourceRoot = ".";

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 olympics.nt -t $out
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  meta = {
    description = "Olympics RDF dataset for use with QLever SPARQL engine";
    homepage = "https://github.com/wallscope/olympics-rdf";
    license = lib.licenses.mit;
    teams = with lib.teams; [ ngi ];
  };
})
