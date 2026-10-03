{
  dezoomify_3,
  fetchFromGitHub,
  rustPlatform,
}:

dezoomify_3.overrideAttrs (old: rec {
  pname = "dezoomify-rolling";
  version = "3.0.241";

  src = fetchFromGitHub {
    owner = "lovasoa";
    repo = "dezoomify";
    tag = "rolling-v${version}";
    hash = "sha256-pR9/2OCtIue5chBrxan5aJpUfcSzpOoZjs8qBiADDnc=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-E/Y4DT0U5FMPYxMZ4yCn9tF0yC76mNGsjYPuUoJE7mI=";
  };
})
