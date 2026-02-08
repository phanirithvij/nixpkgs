{
  autoreconfHook,
  cairo,
  cppunit,
  fetchFromGitHub,
  fetchNpmDepsV2,
  lib,
  libcap,
  libpng,
  libreoffice-collabora,
  nodejs,
  npmHooksV2,
  pam,
  pango,
  pixman,
  pkg-config,
  poco,
  python3,
  rsync,
  stdenv,
  zstd,
  cypress,
  chromium,
  xvfb,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "collabora-online";
  version = "25.04.8-3";

  src = fetchFromGitHub {
    owner = "CollaboraOnline";
    repo = "online";
    tag = "cp-${finalAttrs.version}";
    hash = "sha256-kLJ8w2vMyladeOBbz1dhFQODniT82Ao4kani+snCNM8=";
  };

  patches = [
    # patch to fix node_modules path, for a npm workspace install
    ./0001-fix-node_modules-path.patch
    # WIP
    ./0002-WIP-node_modules-fix.patch
  ];

  postPatch = ''
    cp ${./package.json} package.json
    cp --no-preserve=mode ${./package-lock.json} package-lock.json

    patchShebangs browser/util/*.py coolwsd-systemplate-setup scripts/*
    substituteInPlace configure.ac --replace-fail '/usr/bin/env python3' python3
  '';

  nativeBuildInputs = [
    autoreconfHook
    nodejs
    npmHooksV2.npmConfigHook
    pkg-config
    python3
    python3.pkgs.lxml
    python3.pkgs.polib
    rsync
    chromium
  ];

  buildInputs = [
    cairo
    cppunit
    libcap
    libpng
    pam
    pango
    pixman
    poco
    zstd
  ];

  enableParallelBuilding = true;

  configureFlags = [
    "--disable-setcap"
    "--disable-werror"
    "--enable-cypress"
    "--enable-silent-rules"
    "--with-lo-path=${finalAttrs.passthru.libreoffice}/lib/collaboraoffice"
    "--with-lokit-path=${finalAttrs.passthru.libreoffice.src}/include"
  ];

  # Copy dummy self-signed certificates provided for testing.
  postInstall = ''
    cp etc/ca-chain.cert.pem etc/cert.pem etc/key.pem $out/etc/coolwsd
  '';

  npmDeps = fetchNpmDepsV2 {
    unpackPhase = "true";
    # TODO: Use upstream `npm-shrinkwrap.json` once it's fixed
    # https://github.com/CollaboraOnline/online/issues/9644
    postPatch = ''
      cp ${./package-lock.json} package-lock.json
    '';
    fetcherVersion = 2; # https://github.com/NixOS/nixpkgs/pull/470517
    hash = "sha256-rJG7fhztrt7EjEWKDVixJ/hjKQxA/idZzD6Y+4LH5cY="; # workspace staging + clean install
  };

  env.CYPRESS_INSTALL_BINARY = 0;
  env.CYPRESS_RUN_BINARY = lib.getExe cypress;

  nativeCheckInputs = [
    xvfb
  ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    pushd cypress_test
    make check-desktop
    make check
    popd
    runHook postCheck
  '';

  passthru = {
    libreoffice = libreoffice-collabora; # Used by NixOS module.
    updateScript = ./update.sh;
  };

  meta = {
    description = "Collaborative online office suite based on LibreOffice technology";
    homepage = "https://www.collaboraonline.com";
    license = lib.licenses.mpl20;
    maintainers = [ lib.maintainers.xzfc ];
    platforms = lib.platforms.linux;
    teams = [ lib.teams.ngi ];
  };
})
