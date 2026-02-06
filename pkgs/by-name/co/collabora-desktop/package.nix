{
  lib,
  cypress,
  autoreconfHook,
  cairo,
  cppunit,
  fetchFromGitHub,
  fetchNpmDeps,
  libcap,
  libpng,
  libreoffice-collabora,
  nodejs,
  npmHooks,
  pam,
  pango,
  pixman,
  pkg-config,
  poco,
  python3,
  rsync,
  stdenv,
  zstd,
  kdePackages,
  perl,
  chromium,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "collabora-desktop";
  version = "25.04.8.1-1";
  src = fetchFromGitHub {
    owner = "CollaboraOnline";
    repo = "online";
    tag = "coda-${finalAttrs.version}";
    hash = "sha256-CwafnJiGjOnzA0yMIXlJU/jYnZlZFw0ulK76nZWWmhw=";
  };

  #cp ${./package-lock.json} ${finalAttrs.npmRoot}/package-lock.json
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json

    patchShebangs browser/util/*.py coolwsd-systemplate-setup scripts/*
    substituteInPlace configure.ac --replace-fail '/usr/bin/env python3' python3
  '';

  nativeBuildInputs = [
    autoreconfHook
    perl
    nodejs
    npmHooks.npmConfigHook
    pkg-config
    python3
    python3.pkgs.lxml
    python3.pkgs.polib
    rsync
    # from CollaboraOnline/nix-build-support
    kdePackages.qtbase.dev
    kdePackages.qttools
    (stdenv.mkDerivation {
      name = "qtlibexec";
      src = kdePackages.qtbase;
      buildPhase = ''
        mkdir -p $out
        ln -s ${kdePackages.qtbase}/libexec $out/bin
      '';
    })
    kdePackages.qtbase
    kdePackages.qtwebengine
    kdePackages.wrapQtAppsHook
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

  configureFlags = [
    "--disable-werror"
    "--enable-silent-rules"
    "--with-lo-path=${libreoffice-collabora}/lib/collaboraoffice"
    "--with-lokit-path=${libreoffice-collabora.src}/include"
    "--enable-qtapp"
    # TODO option to disable tests as a top level arg, depending on how long the tests take
    # would increase the vendored lockfiles size (one if tests are enabled, one if not)
    "--enable-cypress"
    "--enable-silent-rules"
    "--disable-ssl"
    # TODO says Development Edition in the title, figure out how to make it the same as the flatpak
    # Doing this is giving errors
    #"--with-vendor=Collabora Productivity Limited"
    #"--with-app-name=Collabora Office"
    "--with-info-url=https://collaboraoffice.com/"
  ];

  enableParallelBuilding = true;

  postInstall = ''
    cp --no-preserve=mode ${libreoffice-collabora}/lib/collaboraoffice/LICENSE.html $out/LICENSE.html
    python3 scripts/insert-coda-license.py $out/LICENSE.html CODA-THIRDPARTYLICENSES.html
  '';

  npmDeps = fetchNpmDeps {
    unpackPhase = "true";
    # TODO: Use upstream `npm-shrinkwrap.json` once it's fixed
    # https://github.com/CollaboraOnline/online/issues/9644
    postPatch = ''
      cp ${./package-lock.json} package-lock.json
    '';
    #hash = "sha256-U7k4lP0wYlm0YY1y3meZSCuPjSpmoVgJCW6ICvPkmfw=";
    hash = "sha256-JGaxnSiraRY6ePk1RQkDIV4fgmBOoCpUHXj0+COtxf8="; # workspace
    #hash = "sha256-Yum6qWpL3kkb/XIBtkAJ+J/Hop2W/v2NP6S6oK5pUI0=";
  };

  # TEMP remove
  #makeCacheWritable = true;
  #npmFlags = [ "--legacy-peer-deps" ];

  #npmRoot = "browser";

  # Needs a zip file
  # TODO expose this from cypress derivation itself
  env.CYPRESS_INSTALL_BINARY = 0;
  env.CYPRESS_RUN_BINARY = lib.getExe cypress;

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
    inherit (finalAttrs) npmDeps;
  };

  meta = {
    description = "Collaborative office suite based on LibreOffice technology";
    license = lib.licenses.mpl20;
    homepage = "https://www.collaboraonline.com/collabora-office/";
    platforms = lib.platforms.linux;
    teams = [ lib.teams.ngi ];
  };
})
