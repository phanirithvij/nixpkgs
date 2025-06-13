{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  threadingSupport ? true, # multi-threading
  openglSupport ? false,
  libglut,
  libGL,
  libGLU, # OpenGL (required for vwebp)
  pngSupport ? true,
  libpng, # PNG image format
  jpegSupport ? true,
  libjpeg, # JPEG image format
  tiffSupport ? true,
  libtiff, # TIFF image format
  gifSupport ? true,
  giflib, # GIF image format
  swap16bitcspSupport ? false, # Byte swap for 16bit color spaces
  libwebpmuxSupport ? true, # Build libwebpmux

  pkgs, # for passthru.tests
}:

stdenv.mkDerivation rec {
  pname = "libwebp";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "webmproject";
    repo = "libwebp";
    rev = "v${version}";
    hash = "sha256-DMHP7DVWXrTsqU0m9tc783E6dNO0EQoSXZTn5kZOtTg=";
  };

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
    (lib.cmakeBool "WEBP_USE_THREAD" threadingSupport)
    (lib.cmakeBool "WEBP_BUILD_VWEBP" openglSupport)
    (lib.cmakeBool "WEBP_BUILD_IMG2WEBP" (pngSupport || jpegSupport || tiffSupport))
    (lib.cmakeBool "WEBP_BUILD_GIF2WEBP" gifSupport)
    (lib.cmakeBool "WEBP_BUILD_ANIM_UTILS" false) # Not installed
    (lib.cmakeBool "WEBP_BUILD_EXTRAS" false) # Not installed
    (lib.cmakeBool "WEBP_ENABLE_SWAP_16BIT_CSP" swap16bitcspSupport)
    (lib.cmakeBool "WEBP_BUILD_LIBWEBPMUX" libwebpmuxSupport)
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs =
    [ ]
    ++ lib.optionals openglSupport [
      libglut
      libGL
      libGLU
    ]
    ++ lib.optionals pngSupport [ libpng ]
    ++ lib.optionals jpegSupport [ libjpeg ]
    ++ lib.optionals tiffSupport [ libtiff ]
    ++ lib.optionals gifSupport [ giflib ];

  passthru.tests = {
    inherit (pkgs)
      gd
      graphicsmagick
      imagemagick
      imlib2
      libjxl
      opencv
      vips
      ;
    inherit (pkgs.python3.pkgs) pillow imread;
    haskell-webp = pkgs.haskellPackages.webp;
  };

  meta = with lib; {
    description = "Tools and library for the WebP image format";
    homepage = "https://developers.google.com/speed/webp/";
    license = licenses.bsd3;
    platforms = platforms.all;
    maintainers = with maintainers; [ ajs124 ];
  };
}
