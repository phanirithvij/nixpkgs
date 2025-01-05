{ mkDprintPlugin, ... }:
let
  version = "0.3.9";
  hash = "sha256-15InHQgF9c0Js4yUJxmZ1oNj1O16FBU12u/GOoaSAJ8=";
  homepage = "https://github.com/dprint/dprint-plugin-ruff";
in
mkDprintPlugin (
  {
    description = "Ruff (Python) wrapper plugin.";
    initConfig = {
      configExcludes = [ ];
      configKey = "ruff";
      fileExtensions = [
        "py"
        "pyi"
      ];
    };
    pname = "dprint-plugin-ruff";
    updateUrl = "https://plugins.dprint.dev/dprint/ruff/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/ruff-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
