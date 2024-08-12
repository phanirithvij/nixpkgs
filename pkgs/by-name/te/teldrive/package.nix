{
  lib,
  buildGoModule,
  fetchFromGitHub,
  stdenvNoCC,
  pnpm,
  nodejs,
}:
buildGoModule rec {
  pname = "teldrive";
  version = "1.4.20";
  src = fetchFromGitHub {
    owner = "divyam234";
    repo = "teldrive";
    rev = "${version}";
    hash = "sha256-6myvRwLTsClMXN65183Pl/HZfGlqA1KZU+nDti7dnxs=";
  };
  vendorHash = "sha256-DuAKMistbD8eKbsTxNwx/rzVxaROsi2doow7DkX33kQ=";
  ldflags = [
    "-s"
    "-X github.com/divyam234/teldrive/internal/config.Version=${version}"
  ];
  # TODO TestSuite needs to be run with postgres running
  # TestTimeout can be fixed
  checkFlags = [ "-skip=TestSuite|Test/TestTimeout" ];
  preBuild = ''
    cp -r ${ui} ui/dist
  '';
  ui = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "teldrive-ui";
    version = "e19fe0f";
    src = fetchFromGitHub {
      owner = "divyam234";
      repo = "teldrive-ui";
      rev = finalAttrs.version;
      hash = "sha256-kNncXVpIx5rH2zvFPtv5F7/BcO7kBJ8FY1fZwhxt0kI=";
    };
    pnpmDeps = pnpm.fetchDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-D2xHZcoewaOTLviJACs086iB+h8bRzq3q1w7inxjF5M=";
    };
    nativeBuildInputs = [
      nodejs
      pnpm.configHook
    ];
    postPatch = ''
      substituteInPlace vite.config.mts \
        --replace-fail "git rev-parse --short HEAD" "echo ${version}"
    '';
    postBuild = ''
      pnpm run build
    '';
    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  });
  meta = with lib; {
    description = "A powerful utility that enables you to organise your telegram files";
    homepage = "https://github.com/divyam234/teldrive";
    changelog = "https://github.com/divyam234/teldrive/releases/latest";
    license = licenses.mit;
    maintainers = with maintainers; [ phanirithvij ];
    mainProgram = "teldrive";
  };
}
