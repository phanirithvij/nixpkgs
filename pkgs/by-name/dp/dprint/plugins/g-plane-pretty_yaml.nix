{ mkDprintPlugin, ... }:
mkDprintPlugin {
  changelog = "https://github.com/g-plane/pretty_yaml/releases/v0.5.0";
  description = "YAML formatter.";
  hash = "sha256-6ua021G7ZW7Ciwy/OHXTA1Joj9PGEx3SZGtvaA//gzo=";
  homepage = "https://github.com/g-plane/pretty_yaml";
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
  url = "https://plugins.dprint.dev/g-plane/pretty_yaml-v0.5.0.wasm";
  version = "v0.5.0";
}
