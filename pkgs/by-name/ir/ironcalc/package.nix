{
  lib,
  callPackage,
  fetchFromGitHub,

  rustPlatform,

  pkg-config,
  python3,
  python3Packages,
  bzip2,
  zstd,

  sqlite,
  writeShellScriptBin,
  symlinkJoin,
  nix-update-script,
}:

let
  version = "0.7.1-unstable-2026-04-29";

  # using applyPatches because sourceRoot is different for the server package
  src = fetchFromGitHub {
    owner = "ironcalc";
    repo = "ironcalc";
    rev = "8461ff71347ab19145cd7ad50ef829181ba765c2";
    hash = "sha256-vjI3M+hS9bXK8QQlopAy6f4dCISfQHGMvN9sMNKp88Q=";
  };

  patches = [
    # nix specific issue, can't reproduce without nix, not upstreaming
    ./0001-FIX-test-message.patch
  ];

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
    inherit patches src version;

    buildAndTestSubdir = "webapp/app.ironcalc.com/server";
    cargoRoot = "webapp/app.ironcalc.com/server";

    cargoHash = "sha256-46IwZJI9AOs+IQFbfz89A2yIi5db7rVMVNsO9W+tn+c=";

    __structedAttrs = true;
    strictDeps = true;

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [
      bzip2
      zstd
    ];

    postInstall = ''
      install -Dm644 webapp/app.ironcalc.com/server/init_db.sql $out/share/ironcalc/init_db.sql
    '';

    meta = meta // {
      description = "IronCalc server package";
      mainProgram = "ironcalc_server";
    };
  };

  frontend_packages = callPackage ./frontend.nix { };

  inherit (frontend_packages)
    frontend
    wasm
    widget
    ;

  tools = rustPlatform.buildRustPackage {
    pname = "ironcalc-tools";
    inherit patches src version;
    inherit cargoHash;

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

    doCheck = true;

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      $out/bin/xlsx_2_icalc 2>&1 | grep "Usage:" || true

      $out/bin/xlsx_2_icalc xlsx/tests/docs/CHOOSE.xlsx test.ic
      test -f test.ic
      runHook postInstallCheck
    '';

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

  python = python3Packages.ironcalc;
  nodejs = callPackage ./nodejs.nix { };
  docs = callPackage ./docs.nix { };
in
symlinkJoin {
  pname = "ironcalc";
  inherit version;
  paths = [
    tools
    wrapper
  ];

  __structedAttrs = true;
  strictDeps = true;

  passthru =
    let
      exports = {
        inherit
          frontend
          widget
          server
          tools
          docs
          wasm
          nodejs
          python
          wrapper
          ;
      };
    in
    {
      inherit
        src
        cargoHash
        ;
      updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
      tests = exports;
    }
    // exports;

  inherit meta;
}
