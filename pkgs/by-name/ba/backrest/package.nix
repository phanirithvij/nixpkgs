{
  buildGoModule,
  fetchFromGitHub,
  gzip,
  iana-etc,
  lib,
  libredirect,
  nodejs,
  pnpm_11,
  fetchPnpmDeps,
  pnpmConfigHook,
  restic,
  stdenv,
  util-linux,
  makeBinaryWrapper,
  versionCheckHook,
}:
let
  pnpm = pnpm_11;

  pname = "backrest";
  version = "1.13.0";

  src = fetchFromGitHub {
    owner = "garethgeorge";
    repo = "backrest";
    tag = "v${version}";
    hash = "sha256-JcrHQDjoaaK6BONEcn6XKsjhGlth4SaZKqfxa3cD0gY=";
    leaveDotGit = true;
    postFetch = ''
      cd "$out"
      git rev-parse HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  frontend = stdenv.mkDerivation (finalAttrs: {
    inherit version src;
    pname = "backrest-webui";
    sourceRoot = "${finalAttrs.src.name}/webui";

    nativeBuildInputs = [
      nodejs
      pnpmConfigHook
      pnpm
    ];

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      inherit pnpm;
      fetcherVersion = 4;
      hash = "sha256-xPZg7kYRlqdO/EfZr+m+IVhDcyYegQ6v8ZAF2EjrKjU=";
    };

    buildPhase = ''
      runHook preBuild
      export BACKREST_BUILD_VERSION=${version}
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mv dist $out
      runHook postInstall
    '';
  });
in
buildGoModule (finalAttrs: {
  inherit pname src version;

  postPatch = ''
    sed -i -e \
      '/func installRestic(targetPath string) error {/a\
        return fmt.Errorf("installing restic from an external source is prohibited by nixpkgs")' \
      internal/resticinstaller/resticinstaller.go
  '';

  proxyVendor = true;
  vendorHash = "sha256-1PecXGXdSu4FzOKVZ15lTLLPy3VlLiGvGeTUDzqe9sc=";

  subPackages = [ "cmd/backrest" ];

  nativeBuildInputs = [
    gzip
    makeBinaryWrapper
  ];

  ldflags = [
    "-s"
    "-X main.version=${finalAttrs.version}"
  ];

  preBuild = ''
    ldflags+=" -X main.commit=$(cat COMMIT)"

    mkdir -p ./webui/dist
    cp -r ${finalAttrs.passthru.frontend}/* ./webui/dist

    go generate -skip="npm" ./...
  '';

  nativeCheckInputs = [
    util-linux
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ libredirect.hook ];

  checkFlags =
    let
      skippedTests = [
        "TestMultihostIndexSnapshots"
        "TestRunCommand"
        "TestSnapshot"
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        "TestBackup" # relies on ionice
        "TestCancelBackup"
        "TestFirstRun" # e2e test requires networking
      ];
    in
    [ "-skip=^${builtins.concatStringsSep "$|^" skippedTests}$" ];

  # Use restic from nixpkgs, otherwise download fails in sandbox
  preCheck = ''
    export BACKREST_RESTIC_COMMAND="${lib.getExe restic}"
    export HOME=$(pwd)
  ''
  + lib.optionalString (stdenv.hostPlatform.isDarwin) ''
    export NIX_REDIRECTS=/etc/protocols=${iana-etc}/etc/protocols:/etc/services=${iana-etc}/etc/services
  '';

  doCheck = true;

  postInstall = ''
    wrapProgram $out/bin/backrest \
      --set-default BACKREST_RESTIC_COMMAND "${lib.getExe restic}"
  '';

  doInstallCheck = true;
  versionCheckProgramArg = "-version";
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru = {
    inherit frontend;
  };

  meta = {
    changelog = "https://github.com/garethgeorge/backrest/releases/tag/${finalAttrs.src.rev}";
    description = "Web UI and orchestrator for restic backup";
    homepage = "https://github.com/garethgeorge/backrest";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ iedame ];
    mainProgram = "backrest";
    platforms = lib.platforms.unix;
  };
})
