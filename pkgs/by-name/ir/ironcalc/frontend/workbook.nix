{
  buildNpmPackage,
  ironcalc,
}:
buildNpmPackage {
  pname = "ironcalc-workbook";
  inherit (ironcalc) version src;
  sourceRoot = "source";

  postPatch = ''
    cd webapp/IronCalc
    chmod -R u+w ../../..
    mkdir -p ../../bindings/wasm/pkg
    echo '{"name": "@ironcalc/wasm", "version": "${ironcalc.version}"}' > ../../bindings/wasm/pkg/package.json
  '';

  npmDepsHash = "sha256-jPnUUEOjW9WHVjpBH/qKB4P5RuMI0uvjog8C41cPQdY=";

  preConfigure = ''
    cp -rv ${ironcalc.wasm}/. ../../bindings/wasm/pkg/
  '';

  buildPhase = ''
    npm run build
  '';

  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';

  __structuredAttrs = true;
  strictDeps = true;

  meta = ironcalc.meta // {
    description = "Ironcalc frontend workbook package";
  };
}
