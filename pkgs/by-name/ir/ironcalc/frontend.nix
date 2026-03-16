{
  rustPlatform,
  buildNpmPackage,
  python3,
  pkg-config,
  binaryen,
  bzip2,
  zstd,
  esbuild,
  wasm-bindgen-cli_0_2_108,
  wasm-pack,
  nodejs,
  typescript,
  lld,
  writableTmpDirAsHomeHook,

  ironcalc,
}:
let
  inherit (ironcalc) version src cargoHash;

  wasm = rustPlatform.buildRustPackage {
    pname = "ironcalc-wasm";
    inherit version src cargoHash;

    nativeBuildInputs = [
      binaryen
      pkg-config
      python3
      wasm-bindgen-cli_0_2_108
      wasm-pack
      nodejs
      typescript
      lld
      writableTmpDirAsHomeHook
    ];

    buildInputs = [
      bzip2
      zstd
    ];

    buildPhase = ''
      cd bindings/wasm
      make tests

      wasm-pack build --target web --scope ironcalc --release
      cp README.pkg.md pkg/README.md
      tsc types.ts --target esnext --module esnext
      python3 fix_types.py
      rm -f types.js

      # wasm-pack generates a package.json, we must provide one
      cat > pkg/package.json <<EOF
      {
        "name": "@ironcalc/wasm",
        "version": "${ironcalc.version}",
        "type": "module",
        "files": [
          "wasm_bg.wasm",
          "wasm.js",
          "wasm.d.ts"
        ],
        "main": "wasm.js",
        "module": "wasm.js",
        "types": "wasm.d.ts",
        "exports": {
          ".": {
            "types": "./wasm.d.ts",
            "import": "./wasm.js"
          }
        },
        "sideEffects": false
      }
      EOF
    '';

    doCheck = true;

    installPhase = ''
      cp -r pkg $out
    '';

    __structedAttrs = true;
    strictDeps = true;

    meta = ironcalc.meta // {
      description = "Ironcalc wasm bindings";
    };
  };

  workbook = buildNpmPackage {
    pname = "ironcalc-workbook";
    inherit version src;
    sourceRoot = "${src.name}/webapp/IronCalc";
    npmDepsHash = "sha256-Yhf+TJ4ihskGVepXm4FRastzM1ruIjrEQighY0MGHtc=";

    postPatch = ''
      chmod -R u+w ../../..
      mkdir -p ../../bindings/wasm/pkg
      echo '{"name": "@ironcalc/wasm", "version": "${ironcalc.version}"}' > ../../bindings/wasm/pkg/package.json
      cp ${./workbook/package-lock.json} package-lock.json
    '';

    preConfigure = ''
      cp -rv ${wasm}/. ../../bindings/wasm/pkg/
    '';

    buildPhase = ''
      npm run build
    '';

    installPhase = ''
      mkdir -p $out
      cp -r . $out
    '';

    __structedAttrs = true;
    strictDeps = true;

    meta = ironcalc.meta // {
      description = "Ironcalc frontend workbook package";
    };
  };

  frontend = buildNpmPackage {
    pname = "ironcalc-frontend";
    inherit version src;
    sourceRoot = "${src.name}/webapp/app.ironcalc.com/frontend";
    npmDepsHash = "sha256-sqAAfIxwhMF5u0prXXLhpnmbUVh+VJ6A+Jq/Rzg9CfM=";

    postPatch = ''
      chmod -R u+w ../../..

      # wasm location fix
      mkdir -p ../../../bindings/wasm/pkg
      cp -rv ${wasm}/. ../../../bindings/wasm/pkg/

      rm -rf ../../IronCalc
      cp -r ${workbook} ../../IronCalc
      chmod -R u+w ../../IronCalc

      cp ${./app/package-lock.json} package-lock.json

      substituteInPlace src/components/WorkbookTitle.tsx \
        --replace-warn 'onInput={handleChange}' 'onChange={handleChange}'
    '';

    preBuild = ''
      # wasm resolution fix
      mkdir -p node_modules/@ironcalc
      cp -rv ${wasm}/. node_modules/@ironcalc/wasm
    '';

    installPhase = ''
      mkdir -p $out
      cp -r dist/. $out
    '';

    __structedAttrs = true;
    strictDeps = true;

    meta = ironcalc.meta // {
      description = "Ironcalc frontend package";
    };
  };
in
frontend
