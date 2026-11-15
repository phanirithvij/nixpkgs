{ pkgs }:
let
  inherit (pkgs) lib;
  mainProgram = "agda-trivial-backend";

  hello-world = ./files/HelloWorld.agda;

  agda-trivial-backend = pkgs.stdenvNoCC.mkDerivation {
    name = "trivial-backend";
    meta = { inherit mainProgram; };
    version = "${pkgs.haskellPackages.Agda.version}";
    src = ./files/TrivialBackend.hs;
    buildInputs = [
      (pkgs.haskellPackages.ghcWithPackages (pkgs: [ pkgs.Agda ]))
    ];
    dontUnpack = true;
    buildPhase = ''
      ghc $src -o ${mainProgram}
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp ${mainProgram} $out/bin
    '';
  };

  agdaPackages = pkgs.agdaPackages.override (oldAttrs: {
    Agda = agda-trivial-backend;
  });

  customAgda = agdaPackages.withPackages {
    pkgs = p: [ p.standard-library ];
  };
in
pkgs.runCommand "agda-trivial-backend-test"
  {
    nativeBuildInputs = [
      customAgda
      pkgs.ghc
    ];
    meta = with lib.maintainers; {
      maintainers = [
        carlostome
      ];
    };
  }
  ''
    export LC_ALL=C.UTF-8

    # agda and agda-mode are not in path
    if command -v agda >/dev/null; then
      echo "agda should not be in path" >&2
      exit 1
    fi
    if command -v agda-mode >/dev/null; then
      echo "agda-mode should not be in path" >&2
      exit 1
    fi

    # backend is present
    ${mainProgram} --help | grep -F "${mainProgram}"

    # Hello world
    cp ${hello-world} HelloWorld.agda
    ${mainProgram} -l standard-library -i . -c HelloWorld.agda

    # Check execution
    output=$(./HelloWorld)
    echo "$output"
    [[ "$output" =~ "Hello World!" ]]

    touch $out
  ''
