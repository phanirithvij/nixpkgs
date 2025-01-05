{ mkDprintPlugin, ... }:
let
  version = "v0.5.0";
  hash = "sha256-6ua021G7ZW7Ciwy/OHXTA1Joj9PGEx3SZGtvaA//gzo=";
  homepage = "https://github.com/g-plane/pretty_yaml";
in
mkDprintPlugin (
  {
    description = "YAML formatter.";
    initConfig = {
      configExcludes = [ ];
      configKey = "yaml";
      fileExtensions = [
        "yaml"
        "yml"
      ];
    };
    pname = "g-plane-pretty_yaml";
    updateUrl = "https://plugins.dprint.dev/g-plane/pretty_yaml/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/g-plane/pretty_yaml-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
