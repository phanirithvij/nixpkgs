{ mkDprintPlugin, ... }:
let
  version = "0.7.1";
  hash = "sha256-+zY+myazFAUxeNuWFigkvF4zpKBs+jzVYQT09jRWFKI=";
  homepage = "https://github.com/dprint/dprint-plugin-biome";
in
mkDprintPlugin (
  {
    description = "Biome (JS/TS) wrapper plugin.";
    initConfig = {
      configExcludes = [ "**/node_modules" ];
      configKey = "biome";
      fileExtensions = [
        "ts"
        "tsx"
        "js"
        "jsx"
        "cjs"
        "mjs"
      ];
    };
    pname = "dprint-plugin-biome";
    updateUrl = "https://plugins.dprint.dev/dprint/biome/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/biome-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
