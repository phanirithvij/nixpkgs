{
  lib,
  stdenv,
  callPackage,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
  pkg-config,
  openssl,
  cacert,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "dezoomify";
  version = "3.0.241";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "lovasoa";
    repo = "dezoomify";
    tag = "rolling-v${finalAttrs.version}";
    hash = "sha256-pR9/2OCtIue5chBrxan5aJpUfcSzpOoZjs8qBiADDnc=";
  };

  nativeBuildInputs = lib.optionals (!stdenv.hostPlatform.isDarwin) [
    pkg-config
  ];

  buildInputs = lib.optionals (!stdenv.hostPlatform.isDarwin) [
    openssl
  ];

  nativeCheckInputs = [
    cacert
  ];

  cargoHash = "sha256-E/Y4DT0U5FMPYxMZ4yCn9tF0yC76mNGsjYPuUoJE7mI=";

  # hyper uses SystemConfiguration.framework to read system proxy settings.
  # Allow access to the Mach service to prevent the tests from failing.
  sandboxProfile = ''
    (allow mach-lookup (global-name "com.apple.SystemConfiguration.configd"))
  '';

  passthru = {
    # TODO restrict to github releases, strip rolling thing?
    updateScript = nix-update-script { };

    # TODO expose as dezoomify-desktop, dezoomify, dezoomify-rs ??
    # TODO decide if all-packages.nix or by-name?
    # TODO this is like caesium (functionality) + ironcalc, asciinema (packaging)
    desktop = callPackage ./desktop.nix { };
    cli = callPackage ./cli.nix { }; # TODO put in package.nix ??
    crx = callPackage ./crx.nix { };
    xpi = callPackage ./xpi.nix { };
    web = callPackage ./web.nix { };
  };

  meta = {
    description = "Zoomable image downloader for Google Arts & Culture, Zoomify, IIIF, and others";
    changelog = "https://github.com/lovasoa/dezoomify/releases/tag/${finalAttrs.src.tag}";
    homepage = "https://github.com/lovasoa/dezoomify";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      fsagbuya
      kybe236
      phanirithvij
    ];
    mainProgram = "dezoomify";
  };
})
