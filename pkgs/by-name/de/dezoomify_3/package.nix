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
  version = "3.0.3";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "lovasoa";
    repo = "dezoomify";
    tag = "v${finalAttrs.version}";
    hash = "sha256-p3aZroiJnkmHDJJAWh3uJEntq5pglqL7hgZdbRQh9n4=";
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

  cargoHash = "sha256-AN2WWCfbfgaWfeIosRgBBnY7GJtmqYsAs2/yWiLS73k=";
  cargoBuildFlags = [ "-p" "dezoomify-cli" ];
  cargoTestFlags = [ "-p" "dezoomify-cli" ];

  # hyper uses SystemConfiguration.framework to read system proxy settings.
  # Allow access to the Mach service to prevent the tests from failing.
  sandboxProfile = ''
    (allow mach-lookup (global-name "com.apple.SystemConfiguration.configd"))
  '';

  postInstall = ''
    mv $out/bin/dezoomify-cli $out/bin/dezoomify
  '';

  passthru = {
    # TODO restrict to github releases, strip rolling thing?
    updateScript = nix-update-script { };

    # TODO expose as dezoomify-desktop, dezoomify, dezoomify-rs ??
    # TODO decide if all-packages.nix or by-name?
    # TODO this is like caesium (functionality) + ironcalc, asciinema (packaging)
    desktop = callPackage ./desktop.nix { inherit (finalAttrs) src version cargoHash; };
    cli = callPackage ./cli.nix { inherit (finalAttrs) src version cargoHash; }; # TODO put in package.nix ??
    crx = callPackage ./crx.nix { inherit (finalAttrs) src version cargoHash; };
    xpi = callPackage ./xpi.nix { inherit (finalAttrs) src version cargoHash; };
    web = callPackage ./web.nix { inherit (finalAttrs) src version cargoHash; };
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
