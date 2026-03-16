{
  lib,
  rustPlatform,
  fetchFromGitHub,

  python3,
  pkg-config,
  bzip2,
  zstd,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ironcalc";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "ironcalc";
    repo = "IronCalc";
    tag = "v${finalAttrs.version}";
    hash = "sha256-P2o/rft5wDOvnjsGV69kaf7L4WObwCGt+aPgzFqqdio=";
  };

  patches = [
    # error message is different
    ./0001-fix-test-message.patch
  ];

  cargoHash = "sha256-q5DnqhIYKUUqfJ4/TNHYF1QgTbH198QtgirQ+lP30wk=";

  nativeBuildInputs = [
    pkg-config
    python3
  ];

  buildInputs = [
    bzip2
    zstd
  ];

  meta = {
    changelog = "TODO";
    description = "Open source selfhosted spreadsheet engine";
    homepage = "https://github.com/ironcalc/IronCalc";
    license = with lib.licenses; [
      asl20
      mit
    ];
    platforms = lib.platforms.unix; # TODO Ideally windows, preferably macos
    mainProgram = "ironcalc";
    maintainers = with lib.maintainers; [ phanirithvij ];
    teams = with lib.teams; [ ngi ];
  };
})
