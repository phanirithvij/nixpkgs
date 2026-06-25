{
  lib,
  bbb-shared-utils,
  buildNpmPackage,
  callPackage,
  makeWrapper,
  nodejs,
}:

let
  mediasoup-worker = callPackage ./mediasoup-worker.nix { };
in
buildNpmPackage {
  pname = "bbb-webrtc-sfu";
  version = bbb-shared-utils.versionComponent;
  src = "${bbb-shared-utils.src}/bbb-webrtc-sfu";

  npmDepsHash = "sha256-hrl3RFB9BUk31s3qbMpEer0HjCujGMrneBhvRThlWVo=";
  forceGitDeps = true;

  dontNpmBuild = true;
  makeCacheWritable = true;

  nativeBuildInputs = [ makeWrapper ];

  env.MEDIASOUP_WORKER_BIN = "${mediasoup-worker}/bin/mediasoup-worker";

  # TODO this should be configurable, so set the defaults
  # TODO this should run from pwd as lib/node_modules/bbb-webrtc-sfu/
  # See its dockerfile
  postInstall = ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe nodejs} $out/bin/bbb-webrtc-sfu \
      --add-flags "$out/lib/node_modules/bbb-webrtc-sfu/server.js" \
      --set MEDIASOUP_WORKER_BIN "${mediasoup-worker}/bin/mediasoup-worker" \
      --set NODE_ENV "production"
  '';

  # TODO move to pkgs/by-name
  passthru = { inherit mediasoup-worker; };

  meta = bbb-shared-utils.meta // {
    description = "BigBlueButton WebRTC SFU";
  };
}
