{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  version = "1.0.13";
  pname = "tinyexr";

  src = fetchFromGitHub {
    owner = "syoyo";
    repo = "tinyexr";
    rev = "v${finalAttrs.version}";
    hash = "sha256-tp+T64qQBIll0ZdZSnEgE2cLijImBXzufebPKskdSU4=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/include
    cp ../*.h ../*.hh $out/include || true
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
