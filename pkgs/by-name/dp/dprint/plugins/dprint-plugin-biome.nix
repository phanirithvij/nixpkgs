{ mkDprintPlugin, ... }:
mkDprintPlugin {
  changelog = "https://github.com/dprint/dprint-plugin-biome/releases/0.7.1";
  description = "Biome (JS/TS) wrapper plugin.";
  hash = "sha256-+zY+myazFAUxeNuWFigkvF4zpKBs+jzVYQT09jRWFKI=";
  homepage = "https://github.com/dprint/dprint-plugin-biome";
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
  url = "https://plugins.dprint.dev/biome-0.7.1.wasm";
  version = "0.7.1";
}
