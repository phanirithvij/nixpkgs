{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  version = "1.0.9";
  pname = "tinyexr";

  src = fetchFromGitHub {
    owner = "syoyo";
    repo = "tinyexr";
    rev = "v${finalAttrs.version}";
    hash = "sha256-gV8MNFiRgMjyOfKWEcbHvkUlnc0oRCDhkpGUzXljCak=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/include
    cp ../*.h $out/include
    cp ../deps/**/*.h $out/include
    cp *.a $out/lib
    runHook postInstall
  '';
  nativeBuildInputs = [ cmake ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Tiny OpenEXR image loader/saver library";
    homepage = "https://github.com/syoyo/tinyexr";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ phanirithvij ];
    platforms = lib.platforms.all;
  };
})
