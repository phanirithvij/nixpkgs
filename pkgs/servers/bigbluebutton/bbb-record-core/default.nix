{
  lib,
  bbb-shared-utils,
  bundlerEnv,
  ruby,
  stdenv,
  makeWrapper,
  systemd,
}:

let
  env = bundlerEnv {
    name = "bbb-record-core-env";
    inherit ruby;
    gemdir = ./.;
    gemConfig = {
      journald-native = attrs: {
        buildInputs = (attrs.buildInputs or [ ]) ++ [ systemd ];
      };
    };
  };
in
stdenv.mkDerivation {
  pname = "bbb-record-core";
  version = bbb-shared-utils.versionComponent;

  src = "${bbb-shared-utils.src}/record-and-playback/core";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    env
    ruby
  ];

  installPhase = ''
    mkdir -p $out/bin $out/lib
    cp -r scripts lib $out/

    # Wrap the scripts with the ruby environment
    for f in $out/scripts/*; do
      if [ -f "$f" ] && [ -x "$f" ]; then
        wrapProgram "$f" \
          --prefix PATH ":" "${env}/bin"
      fi
    done
  '';

  meta = bbb-shared-utils.meta // {
    description = "BigBlueButton Record Core";
  };
}
