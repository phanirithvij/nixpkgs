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
  version = "0.7.1-unstable-2026-04-29";

  # using applyPatches because sourceRoot is different for the server package
  src = applyPatches {
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
    cargoHash = "sha256-46IwZJI9AOs+IQFbfz89A2yIi5db7rVMVNsO9W+tn+c=";

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
