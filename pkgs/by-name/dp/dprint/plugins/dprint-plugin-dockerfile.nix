{ mkDprintPlugin, ... }:
mkDprintPlugin {
  changelog = "https://github.com/dprint/dprint-plugin-dockerfile/releases/0.3.2";
  description = "Dockerfile code formatter.";
  hash = "sha256-gsfMLa4zw8AblOS459ZS9OZrkGCQi5gBN+a3hvOsspk=";
  homepage = "https://github.com/dprint/dprint-plugin-dockerfile";
  initConfig = {
    configExcludes = [ ];
    configKey = "dockerfile";
    fileExtensions = [ "dockerfile" ];
  };
  pname = "dprint-plugin-dockerfile";
  updateUrl = "https://plugins.dprint.dev/dprint/dockerfile/latest.json";
  url = "https://plugins.dprint.dev/dockerfile-0.3.2.wasm";
  version = "0.3.2";
}
