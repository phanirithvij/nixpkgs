{
  lib,
  python3Packages,
  fetchFromGitHub,
  gh,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "gitfetch";
  version = "1.4.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Matars";
    repo = "gitfetch";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WiMLpdj9p4fGxdMUlsNnGv0METgrCtpaCvTVm2474oE=";
  };

  build-system = with python3Packages; [ setuptools ];

  dependencies = with python3Packages; [
    requests
    readchar
    webcolors
  ];

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${lib.makeBinPath [
      gh
    ]}"
  ];

  meta = {
    description = "Neofetch-style CLI tool for git provider statistics";
    homepage = "https://github.com/Matars/gitfetch";
    changelog = "https://github.com/Matars/gitfetch/releases/tag/${finalAttrs.src.tag}";
    mainProgram = "gitfetch";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ lonerOrz ];
  };
})
