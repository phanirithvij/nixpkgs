{
  lib,
  stdenv,
  bbb-shared-utils,
}:

stdenv.mkDerivation {
  pname = "bbb-graphql-server";
  version = bbb-shared-utils.versionComponent;
  src = "${bbb-shared-utils.src}/bbb-graphql-server";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/bbb-graphql-server
    cp -r bbb_schema.sql metadata config.yaml $out/share/bbb-graphql-server

    runHook postInstall
  '';

  meta = bbb-shared-utils.meta // {
    description = "GraphQL server component for BigBlueButton";
  };
}
