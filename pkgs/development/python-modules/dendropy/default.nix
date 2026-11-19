{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  setuptools,
  paup-cli,
  paupIntegration ? false,
}:

let
  paupPath = if paupIntegration then lib.getExe paup-cli else "NONE";
in
buildPythonPackage rec {
  pname = "dendropy";
  version = "5.1.1";

  pyproject = true;
  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "jeetsukumaran";
    repo = "dendropy";
    tag = "v${version}";
    hash = "sha256-Kg0we/hi3HgvFHoF93Qq/JuGgxqKS08vkA2ILCzxhZg=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace '["pytest-runner"],' '[],'

    substituteInPlace src/dendropy/interop/paup.py \
      --replace 'PAUP_PATH = os.environ.get(metavar.DENDROPY_PAUP_PATH_ENVAR, "paup")' 'PAUP_PATH = os.environ.get(metavar.DENDROPY_PAUP_PATH_ENVAR, "${paupPath}")'
  '';

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "dendropy" ];

  meta = {
    description = "Python library for phylogenetic computing";
    homepage = "https://jeetsukumaran.github.io/DendroPy/";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [
      unode
      pandapip1
    ];
  };
}
