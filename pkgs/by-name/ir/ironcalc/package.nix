{
  lib,
  applyPatches,
  callPackage,
  fetchFromGitHub,

  rustPlatform,

  pkg-config,
  python3,
  bzip2,
  zstd,

  sqlite,
  writeShellScriptBin,
  symlinkJoin,
}:

let
  version = "0.7.1";

  src = applyPatches {
    src = fetchFromGitHub {
      owner = "ironcalc";
      repo = "ironcalc";
      tag = "v${version}";
      hash = "sha256-P2o/rft5wDOvnjsGV69kaf7L4WObwCGt+aPgzFqqdio=";
    };
    patches = [
      # remove once https://github.com/ironcalc/IronCalc/pull/896 is merged
      ./0001-FIX-handle-en-GB-client-side-model-loading.patch
      ./0002-FIX-handle-missing-models-as-404.patch
      ./0003-UPDATE-add-option-to-specify-webapp-dir.patch
      ./0004-FIX-update-incorrect-dependencies-in-cargo-lock.patch
      ./0005-FIX-add-missing-t-dependency-to-App.tsx-useEffect.patch

      # nix specific issue, can't reproduce without nix, not upstreaming
      ./0006-FIX-test-message.patch
    ];
  };

  cargoHash = "sha256-q5DnqhIYKUUqfJ4/TNHYF1QgTbH198QtgirQ+lP30wk=";

  meta = {
    description = "Open source selfhosted spreadsheet engine";
    homepage = "https://github.com/ironcalc/IronCalc";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "ironcalc";
    maintainers = with lib.maintainers; [ phanirithvij ];
    teams = with lib.teams; [ ngi ];
  };

  server = rustPlatform.buildRustPackage {
    pname = "ironcalc-server";
    inherit version src;
    sourceRoot = "${src.name}/webapp/app.ironcalc.com/server";

    # cargoPatches not required as we use applyPatches

    cargoHash = "sha256-0Zns6Hp0IfGEzm+50B2GlxuIJt14kXv7iaN37b+GG/g=";

    __structedAttrs = true;
    strictDeps = true;

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [
      bzip2
      zstd
    ];

    postInstall = ''
      install -Dm644 init_db.sql $out/share/ironcalc/init_db.sql
    '';

    meta = meta // {
      description = "IronCalc server package";
      mainProgram = "ironcalc_server";
    };
  };

  frontend = callPackage ./frontend.nix {
    ironcalc = {
      inherit
        src
        version
        cargoHash
        meta
        ;
    };
  };

  tools = rustPlatform.buildRustPackage {
    pname = "ironcalc-tools";
    inherit version src cargoHash;

    __structedAttrs = true;
    strictDeps = true;

    nativeBuildInputs = [
      pkg-config
      python3
    ];

    buildInputs = [
      bzip2
      zstd
    ];

    meta = meta // {
      description = "IronCalc helper tools";
      mainProgram = "xlsx_2_icalc";
    };
  };

  wrapper = writeShellScriptBin "ironcalc" ''
    set -euo pipefail

    IRONCALC_DB_PATH="''${IRONCALC_DB_PATH:-ironcalc.sqlite}"
    if [ ! -f "$IRONCALC_DB_PATH" ]; then
      echo "Initializing database..."
      ${lib.getExe sqlite} "$IRONCALC_DB_PATH" < "${server}/share/ironcalc/init_db.sql"
    fi

    export ROCKET_DATABASES="{ironcalc={url=\"$IRONCALC_DB_PATH\"}}"
    export IRONCALC_WEBAPP_DIR="''${IRONCALC_WEBAPP_DIR:-${frontend}}"
    exec ${server}/bin/ironcalc_server "$@"
  '';
in
symlinkJoin {
  name = "ironcalc-${version}";
  paths = [
    tools
    wrapper
  ];

  __structedAttrs = true;
  strictDeps = true;

  inherit meta;

  passthru = {
    inherit
      frontend
      server
      tools
      wrapper
      ;
  };
}
