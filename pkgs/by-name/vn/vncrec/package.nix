{
  lib,
  stdenv,
  fetchpatch2,
  fetchurl,
  libX11,
  xorgproto,
  imake,
  gccmakedep,
  libXt,
  libXmu,
  libXaw,
  libXext,
  libSM,
  libICE,
  libXpm,
  libXp,
}:

stdenv.mkDerivation {
  pname = "vncrec";
  version = "0.2"; # version taken from Arch AUR

  src = fetchurl {
    url = "http://ronja.twibright.com/utils/vncrec-twibright.tgz";
    hash = "sha256-DPoX2cldhWcvcxu5d03QdNb+K4gJvvwYYrBd7ErJ5vo=";
  };

  patches = [
    # this patch fixes the build
    ./fixes.patch
    # this patch adds unix_socket support, added by maintainer @phanirithvij
    (fetchpatch2 {
      name = "unix_socket.patch";
      url = "https://github.com/phanirithvij/vncrec-twibright/commit/ae1637dfcbf0448cd87960f8e9d45a35a4383ef3.patch?full_index=1";
      hash = "sha256-EFpidPwaTn+BDTdelVxWj7gyKWUHj7pdzuQ42mN2xQs=";
    })
  ];

  hardeningDisable = [ "format" ];

  nativeBuildInputs = [
    imake
    gccmakedep
  ];
  buildInputs = [
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
  ];

  makeFlags = [
    "BINDIR=${placeholder "out"}/bin"
    "MANDIR=${placeholder "out"}/share/man"
  ];
  installTargets = [
    "install"
    "install.man"
  ];

  meta = {
    description = "VNC recorder";
    homepage = "http://ronja.twibright.com/utils/vncrec/";
    license = lib.licenses.gpl2Plus;
    mainProgram = "vncrec";
    maintainers = with lib.maintainers; [ phanirithvij ];
    platforms = lib.platforms.linux;
  };
}
