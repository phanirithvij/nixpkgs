{ mkDprintPlugin, ... }:
let
  version = "0.1.5";
  hash = "sha256-877CEZbMlj9cHkFtl16XCnan37SeEGUL3BHaUKUv8S4=";
  homepage = "https://github.com/dprint/dprint-plugin-jupyter";
in
mkDprintPlugin (
  {
    description = "Jupyter notebook code block formatter.";
    initConfig = {
      configExcludes = [ ];
      configKey = "jupyter";
      fileExtensions = [ "ipynb" ];
    };
    pname = "dprint-plugin-jupyter";
    updateUrl = "https://plugins.dprint.dev/dprint/jupyter/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/jupyter-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
