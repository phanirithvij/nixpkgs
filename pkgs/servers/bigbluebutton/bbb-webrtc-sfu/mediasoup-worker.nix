{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  gcc-unwrapped,
}:

# TODO source build
# https://github.com/taigachat/taigachat/blob/37d8906d257b0bbbfe1ef9b994bee85b88d3d170/Server/MediaWorker/default.nix#L32
stdenv.mkDerivation (finalAttrs: {
  pname = "mediasoup-worker";
  version = "3.14.14";

  src = fetchurl {
    url = "https://github.com/versatica/mediasoup/releases/download/${finalAttrs.version}/mediasoup-worker-${finalAttrs.version}-linux-x64-kernel6.tgz";
    hash = "sha256-njA6hRMofIAArDHMqRta0+oyY5wVid0bDu35wtOEgnw=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [ gcc-unwrapped.lib ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    cp mediasoup-worker $out/bin/
    chmod +x $out/bin/mediasoup-worker
  '';

  meta = {
    description = "Mediasoup worker binary";
    homepage = "https://mediasoup.org";
    license = lib.licenses.isc;
    platforms = [ "x86_64-linux" ];
  };
})
