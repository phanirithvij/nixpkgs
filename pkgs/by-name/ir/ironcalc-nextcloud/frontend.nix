{
  buildNpmPackage,
  fetchNpmDeps,

  jq,
  moreutils,
  npm-lockfile-fix,

  ironcalc,
  ironcalc-nextcloud, # self
}:
let
  wasm =
    (ironcalc.wasm.override {
      inherit (ironcalc-nextcloud) ironcalc;
    }).overrideAttrs
      {
        pname = "ironcalc-nextcloud-wasm";
      };

  workbook =
    (ironcalc.workbook.override {
      inherit (ironcalc-nextcloud) ironcalc;
    }).overrideAttrs
      {
        pname = "ironcalc-nextcloud-workbook";
      };

  # This cannot be deduplicated with ironcalc.frontend
  frontend = buildNpmPackage rec {
    pname = "ironcalc-nextcloud-frontend";
    inherit (ironcalc-nextcloud) version src;
    sourceRoot = "source/frontend";
    npmDeps = fetchNpmDeps {
      inherit (ironcalc-nextcloud) src;
      sourceRoot = "source/frontend";
      name = "ironcalc-nextcloud-frontend-${version}-npm-deps";
      hash = "sha256-scSqKWjba13u1qoTxyU//81KIZdzgQdmCZk9VMTAz2I=";
      npmDepsFetcherVersion = 3;

      nativeBuildInputs = [
        jq
        moreutils
        npm-lockfile-fix
      ];

      # remove vendored workbook tarball
      # and fix the missing resolved urls in package-lock.json
      postPatch = ''
        jq 'del(.dependencies["@ironcalc/workbook"])' package.json | sponge package.json
        jq '
          del(.packages[""].dependencies["@ironcalc/workbook"]) |
          del(.packages["node_modules/@ironcalc/workbook"]) |
        ' package-lock.json | sponge package-lock.json

        npm-lockfile-fix package-lock.json
      '';

      postBuild = ''
        cp package.json $out
      '';
    };

    makeCacheWritable = true;

    postPatch = ''
      cp ${npmDeps}/package.json package.json
      cp ${npmDeps}/package-lock.json package-lock.json
    '';

    preBuild = ''
      mkdir -p node_modules/@ironcalc/workbook
      cp -rv ${ironcalc-nextcloud.workbook}/. node_modules/@ironcalc/workbook
    '';

    installPhase = ''
      mkdir -p $out
      cp -r dist/. $out
    '';

    __structuredAttrs = true;
    strictDeps = true;

    meta = ironcalc.meta // {
      description = "Ironcalc nextcloud frontend package";
    };
  };
in
{
  inherit
    wasm
    workbook
    frontend
    ;
}
