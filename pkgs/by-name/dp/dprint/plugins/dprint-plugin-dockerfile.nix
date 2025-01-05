{ mkDprintPlugin, ... }:
let
  version = "0.3.2";
  hash = "sha256-gsfMLa4zw8AblOS459ZS9OZrkGCQi5gBN+a3hvOsspk=";
  homepage = "https://github.com/dprint/dprint-plugin-dockerfile";
in
mkDprintPlugin (
  {
    description = "Dockerfile code formatter.";
    initConfig = {
      configExcludes = [ ];
      configKey = "dockerfile";
      fileExtensions = [ "dockerfile" ];
    };
    pname = "dprint-plugin-dockerfile";
    updateUrl = "https://plugins.dprint.dev/dprint/dockerfile/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/dockerfile-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
