/*
  TODO
  - nur-pkgs
  - rclone drv
  - run package tests inside nixosTests
*/
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
  version = "1.5.6";
  src = fetchFromGitHub {
    owner = "tgdrive";
    repo = "teldrive";
    tag = "${version}";
    hash = "sha256-4T457i0nSQz+qK3nAhj/YqDL0KQxu3+YOfSkAV05MZs=";
  };
  vendorHash = "sha256-rcEUkcfc4782YV2lfx9telrLv3drNLFAUoM6RnoKveg=";
  ldflags = [
    "-s"
    "-X github.com/tgdrive/teldrive/internal/config.Version=${version}"
  ];
  # TODO TestSuite needs to be run with postgres running
  # TestTimeout can be fixed
  checkFlags = [ "-skip=TestSuite|Test/TestTimeout" ];
  preBuild = ''
    cp -r ${frontend} ui/dist
  '';
  frontend = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "teldrive-ui";
    version = "46598bc";
    src = fetchFromGitHub {
      owner = "tgdrive";
      repo = "teldrive-ui";
      rev = finalAttrs.version;
      hash = "sha256-d+v5wUGIxyLzHzSidLULktOOXOuMPUjZIxk1igN3MRo=";
    };
    pnpmDeps = pnpm.fetchDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-/kD43DdxUq4a9okKzzA+mjlkpeTd2ZQ5/q0UO30vq0g=";
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
  passthru = { inherit frontend; };
  meta = {
    description = "A powerful utility that enables you to organise your telegram files";
    homepage = "https://github.com/divyam234/teldrive";
    changelog = "https://github.com/divyam234/teldrive/releases/latest";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ phanirithvij ];
    mainProgram = "teldrive";
  };
}
