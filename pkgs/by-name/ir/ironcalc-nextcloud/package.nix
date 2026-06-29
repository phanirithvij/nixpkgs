{
  lib,
  callPackage,
  fetchFromGitHub,

  rustPlatform,

  pkg-config,
  bzip2,
  openssl,
  zstd,
  stdenv,

  coreutils,
  sqlite,
  symlinkJoin,
  writeShellApplication,

  ironcalc,
}:

let
  version = "0.7.1-unstable-2026-04-17";
  ironcalc' = ironcalc.overrideAttrs (_: {
    inherit version;
    src = fetchFromGitHub {
      owner = "jvdp";
      repo = "IronCalc";
      rev = "e40c4df5dfb7e68c8e5f8583e63fb954c6183707";
      hash = "sha256-ZWJ9m3YLYWoje9CTOw/F8x94DWzFGV3jX4ItY9gNFjU=";
    };
    inherit meta;
  });

  src = fetchFromGitHub {
    owner = "jvdp";
    repo = "IronCalc-Nextcloud";
    rev = "88c13a7f1d617ebb07b16fb99678d6989d0d3b2d";
    hash = "sha256-UD5ZMHqMeyfkPH6D3kZt7yO6XCt73mZt2gCX8lhEZv8=";
  };

  meta = {
    description = "Ironcalc for Nextcloud";
    homepage = "https://github.com/jvdp/IronCalc-Nextcloud";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "ironcalc-nextcloud";
    maintainers = with lib.maintainers; [ phanirithvij ];
    teams = with lib.teams; [ ngi ];
    # TODO decide
    # see checkNoDefaultFeatures below
    broken = stdenv.hostPlatform.isAarch64;
  };

  server = rustPlatform.buildRustPackage {
    pname = "ironcalc-server";
    inherit src version;

    buildAndTestSubdir = "server";
    cargoRoot = "server";

    cargoHash = "sha256-T2veAd6R21DNJLJSAqMiHwxqs2BC+SesbbufH9khh5M=";

    __structuredAttrs = true;
    strictDeps = true;

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [
      bzip2
      zstd
      openssl
    ];

    meta = meta // {
      mainProgram = "ironcalc_nextcloud_server";
    };
  };

  frontend_packages = callPackage ./frontend.nix { };

  inherit (frontend_packages)
    frontend
    wasm
    workbook
    ;

  # TODO nexcloud register script

  wrapper = writeShellApplication {
    name = "ironcalc";

    runtimeInputs = [
      coreutils
      sqlite
      server
    ];

    text = ''
      IRONCALC_DB_PATH="''${IRONCALC_DB_PATH:-ironcalc.sqlite}"
      mkdir -p "$(dirname "$IRONCALC_DB_PATH")"

      if [ ! -f "$IRONCALC_DB_PATH" ]; then
        echo "Initializing database..."
        sqlite3 "$IRONCALC_DB_PATH" < "${server}/share/ironcalc/init_db.sql"
      fi

      export ROCKET_DATABASES="{ironcalc={url=\"$IRONCALC_DB_PATH\"}}"
      export IRONCALC_WEBAPP_DIR="''${IRONCALC_WEBAPP_DIR:-${frontend}}"

      exec ironcalc_server "$@"
    '';
  };
in
symlinkJoin {
  pname = "ironcalc-nextcloud";
  inherit version;
  paths = [
    wrapper
  ];

  __structuredAttrs = true;
  strictDeps = true;

  passthru =
    let
      exports = {
        inherit
          frontend
          workbook
          server
          wasm
          wrapper
          ;
      };
    in
    {
      updateScript = [ ./update.sh ];
      tests = exports;
      ironcalc = ironcalc';
    }
    // exports;

  inherit meta;
}
