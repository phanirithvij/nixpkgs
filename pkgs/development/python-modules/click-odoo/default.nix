{
  buildPythonPackage,
  click,
  fetchFromGitHub,
  lib,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "click-odoo";
  version = "1.8.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "acsone";
    repo = "click-odoo";
    tag = version;
    hash = "sha256-dUTAu02iSA0YvF/nQYOyb5gzbT8zMedXXwU7yONBrl4=";
  };

  build-system = [ setuptools-scm ];

  dependencies = [ click ];

  meta = {
    description = "Odoo scripting helper library";
    mainProgram = "click-odoo";
    homepage = "https://github.com/acsone/click-odoo";
    license = lib.licenses.lgpl3Only;
    maintainers = with lib.maintainers; [ yajo ];
  };
}
