{
  buildNpmPackage,
  ironcalc,
}:
buildNpmPackage {
  pname = "ironcalc-frontend";
  inherit (ironcalc) version src;
  sourceRoot = "source";

  postPatch = ''
    cd webapp/app.ironcalc.com/frontend
    chmod -R u+w ../../..

    # wasm location fix
    mkdir -p ../../../bindings/wasm/pkg
    cp -rv ${ironcalc.wasm}/. ../../../bindings/wasm/pkg/

    rm -rf ../../IronCalc
    cp -r ${ironcalc.workbook} ../../IronCalc
    chmod -R u+w ../../IronCalc

    substituteInPlace src/components/WorkbookTitle.tsx \
      --replace-warn 'onInput={handleChange}' 'onChange={handleChange}'
  '';

  npmDepsHash = "sha256-QVpUV3dxaqiWCF8RC1MR2ylYC500Lbp5pJgzzOrF20c=";

  preBuild = ''
    # wasm resolution fix
    mkdir -p node_modules/@ironcalc
    cp -rv ${ironcalc.wasm}/. node_modules/@ironcalc/wasm
  '';

  installPhase = ''
    mkdir -p $out
    cp -r dist/. $out
  '';

  __structuredAttrs = true;
  strictDeps = true;

  meta = ironcalc.meta // {
    description = "Ironcalc frontend package";
  };
}
