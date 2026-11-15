{ pkgs }:

let
  inherit (pkgs) lib;
  hello-world = ./files/HelloWorld.agda;
  agdaWithStdlib = pkgs.agda.withPackages (p: [ p.standard-library ]);
in
pkgs.runCommand "agda-base-test"
  {
    nativeBuildInputs = [
      agdaWithStdlib
      pkgs.ghc
    ];
    meta = with lib.maintainers; {
      maintainers = [
        alexarice
        turion
      ];
    };
  }
  ''
    # agda and agda-mode are in path
    agda --version

    # Minimal script that typechecks
    touch TestEmpty.agda
    agda TestEmpty.agda

    # Hello world
    cp ${hello-world} HelloWorld.agda
    agda -l standard-library -i . -c HelloWorld.agda

    # Check execution
    output=$(./HelloWorld)
    echo "$output"
    [[ "$output" =~ "Hello World!" ]]

    touch $out
  ''
