{ mkDprintPlugin, ... }:
let
  version = "0.6.4";
  hash = "sha256-4g/nu8Wo7oF+8OAyXOzs9MuGpt2RFGvD58Bafnrr3ZQ=";
  homepage = "https://github.com/dprint/dprint-plugin-toml";
in
mkDprintPlugin (
  {
    description = "TOML code formatter.";
    initConfig = {
      configExcludes = [ ];
      configKey = "toml";
      fileExtensions = [ "toml" ];
    };
    pname = "dprint-plugin-toml";
    updateUrl = "https://plugins.dprint.dev/dprint/toml/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/toml-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
