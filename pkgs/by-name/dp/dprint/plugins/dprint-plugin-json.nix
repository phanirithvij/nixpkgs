{ mkDprintPlugin, ... }:
let
  version = "0.19.4";
  hash = "sha256-Sw+HkUb4K2wrLuQRZibr8gOCR3Rz36IeId4Vd4LijmY=";
  homepage = "https://github.com/dprint/dprint-plugin-json";
in
mkDprintPlugin (
  {
    description = "JSON/JSONC code formatter.";
    initConfig = {
      configExcludes = [ "**/*-lock.json" ];
      configKey = "json";
      fileExtensions = [ "json" ];
    };
    pname = "dprint-plugin-json";
    updateUrl = "https://plugins.dprint.dev/dprint/json/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/json-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
