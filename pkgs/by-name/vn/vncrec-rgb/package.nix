{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch2,
  imake,
  gccmakedep,
  libjpeg_turbo,
  libX11,
  libXt,
  libXmu,
  libXaw,
  libXext,
  libSM,
  libICE,
  libXpm,
  libXp,
  xorgproto,
  zlib,
}:
stdenv.mkDerivation {
  pname = "vncrec-rgb";
  version = "0.4-unstable-2015-07-30";

  src = fetchFromGitHub {
    owner = "bingmann";
    repo = "vncrec";
    rev = "dafb79c200d3299623d6a5d854a4f01f20b867e1";
    hash = "sha256-5si4FPZmCBH1MqQeSHftZ3I5I+Szax2v8NcZmGt+EWU=";
  };

  patches = [
    ./fixes.patch
    (fetchpatch2 {
      name = "allow-hidden-window.patch";
      url = "https://github.com/bingmann/vncrec/pull/13.patch?full_index=1";
      hash = "sha256-+2exJ/OOwvIOT00dflJZrEmK/PvxndlZZ3EZeHHxfOs=";
    })
    (fetchpatch2 {
      name = "unix-socket-support.patch";
      url = "https://github.com/phanirithvij/vncrec-rgb/commit/a070f01adb16afa3efe8ac42f61a9d7b1316b550.patch?full_index=1";
      hash = "sha256-ToOVKtRQWPs06eqoBgSLogx1eBWHEjtrHqJKR52VLlE=";
    })
  ];

  hardeningDisable = [ "format" ];

  nativeBuildInputs = [
    imake
    gccmakedep
  ];
  buildInputs = [
    libjpeg_turbo
    libX11
    xorgproto
    libXt
    libXmu
    libXaw
    libXext
    libSM
    libICE
    libXpm
    libXp
    zlib
  ];

  makeFlags = [
    "BINDIR=${placeholder "out"}/bin"
    "MANDIR=${placeholder "out"}/share/man"
  ];
  installTargets = [
    "install"
    "install.man"
  ];

  dontStrip = true;

  meta = {
    description = "VNC recorder patched, with rgb support";
    homepage = "https://github.com/bingmann/vncrec";
    platforms = lib.platforms.linux;
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ phanirithvij ];
    mainProgram = "vncrec";
  };
}
