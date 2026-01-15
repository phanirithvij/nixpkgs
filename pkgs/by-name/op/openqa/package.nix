{
  lib,
  perl,
  ruby,
  bundlerEnv,
  stdenv,
  fetchFromGitHub,
  buildNpmPackage,
  unstableGitUpdater,
  nixosTests,
}:
/*
  todo:
    os-autoinst
      ocr
      tests
    openqa
      assetpack client main worker
      tests coverage (mcp ?)
      multiple drvs?
        openqa-client
        opeqna-worker
    nixosTests for openqa deployment and basic testing
      no checkPhase ?

   note:
     I will likely never run opensuse on baremetal
       exception is to verify nixified openqa works and if a vm is not enough
       reasons for nixifying it
         like the look and feel of openqa dashboard
     check opensuse/fedora/debian packages
     check how hydra is nixified (it is also written in perl)
     other perl/js projects eg. lanraragi
     test thouroughly for a few months outside nixpkgs before asking for upstreaming
     phanirithvij/nixqa maybe

   usecases:
      leverage nix to provision openqa full suite
      test other distributions with this openqa
      test nixos with this openqa
      nixosTests has a better ui for screenshots and timeline by directly using openqa

   justification:
      why nixify at all, run it in docker or something
      why rely on another project's test setup
      why duplicate testing setup, confusing for everyone, should we write 2 tests from now on?
      prefer to get just needles idea, dashboard idea and adopt in nixosTests, don't need openqa
        see @nixosTests below

   later:
     openqa perl tests for nixos
       copy and adapt from debian/fedora/opensuse/gnome
       remove FHSisms
       how to keep it up-to-date with other distro's tests
     nixosTests + openqa integration and dashboard
       idea is each nixosTests can spawn a worker and os-autoinst
       dashboard is os-autoinst with native nixosTests understanding
     openqa.nixos.org

     @nixosTests:
       needles
       add a basic screenshot viewer dashboard for hydra
         screenshots and timestamps exposed in $out/nixosTests/capture.json etc.
       vnc capture in nixosTests
         k900, mweinelt already rejected exposing this (for storage costs concerns)
           they were fine with it existing in nixpkgs for others to use
         video capture client side support in hydra like openqa

     investigate using obs (open build service) as an alternative to hydra for nixos
       unlikey to happen given obs likely assumes it is opensuse unlike openqa which allows fedora/debian somehow
       obs.nixos.org

     hydra rust rewrite (someone likely will do it, queue-runners already in rust)
     hydra-tui
       use hydra-check and create it
     openqa-tui (optional sixel/kitty protocl support)
       check if it exists
*/
let
  src = fetchFromGitHub {
    owner = "os-autoinst";
    repo = "openQA";
    rev = "462b395724ddcfb8c648799d3d4e3b10dfea2835";
    hash = "sha256-hesXbsokjdL8DpaY8wiqEZTNftQtWnbUM+bUPmgZi6w=";
  };

  rubyEnv = bundlerEnv {
    name = "sass-dep";
    gemdir = ./.;
    inherit ruby;
  };

  perlEnv = perl.withPackages (
    # native
    pp: with pp; [
      # assetpack
      CSSMinifierXS
      JavaScriptMinifierXS
      Mojolicious
      MojoliciousPluginAssetPack
      YAMLPP

      # main
      FeatureCompatTry
    ]
  );

  assetcache = buildNpmPackage (finalAttrs: {
    pname = "openqa-assetcache";
    version = "hem";
    inherit src;
    # native or not for each
    nativeBuildInputs = [
      rubyEnv
      rubyEnv.wrappedRuby
      perlEnv
    ];
    buildPhase = ''
      runHook preBuild
      patchShebangs tools/generate-packed-assets
      tools/generate-packed-assets
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r --parents assets/cache assets/assetpack.db node_modules $out
      runHook postInstall
    '';
    npmDepsHash = "sha256-Hy1g+IvE+SNJNT3s5uM/WlkpZ0kWDJ4+TjizOXp0jPg=";
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "openqa";
  # rolling release with master as stable branch
  version = "xx"; # TODO check opensuse/fedora/debian packages
  inherit src;

  # dependencies.yaml -> cpanfile
  nativeBuildInputs = [
    #rubyEnv
    #rubyEnv.wrappedRuby
    perlEnv
    # nodejs
    # pgql ?
  ];

  buildPhase = ''
    runHook preBuild
    patchShebangs tools/*
    substituteInPlace Makefile \
      --replace-fail "./tools/generate-packed-assets" ""
    cp -r ${finalAttrs.passthru.deps.assetcache} .
    # maybe conditional on enableParallelBuilding
    env DESTDIR=$out make -j$NIX_BUILD_CORES install-generic
    runHook postBuild
  '';

  installFlags = [
    "DESTDIR=$(out)"
  ];

  /*
    TODO updateScript
    updates can be too frequent because of the rolling release model
      see how fedora/opensuse leap? (rolling release) does it
    tied to os-autoinst likely
    unstableGitUpdater is not enough, dependencies.yaml could change
  */
  passthru.updateScript = unstableGitUpdater { };
  passthru.deps.assetcache = assetcache;

  # TODO nixosTests
  # tests could test some openqa tests for debian/fedora/gnome/opensuse
  passthru.tests = {
    /*
      inherit (nixosTests)
        openqa-base
        os-autoinst-base
        #openqa-full
        #os-autoinst-full
        #openqa-gnome
        #os-autoinst-gnome
        ;
    */
  };

  meta = {
    description = "openQA web-frontend, scheduler and tools";
    homepage = "https://open.qa";
    downloadPage = "https://github.com/os-autoinst/openQA";
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ phanirithvij ];
  };
})
