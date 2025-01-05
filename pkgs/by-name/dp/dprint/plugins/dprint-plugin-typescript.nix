{ mkDprintPlugin, ... }:
let
  version = "0.93.3";
  hash = "sha256-urgKQOjgkoDJCH/K7DWLJCkD0iH0Ok+rvrNDI0i4uS0=";
  homepage = "https://github.com/dprint/dprint-plugin-typescript";
in
mkDprintPlugin (
  {
    description = "TypeScript/JavaScript code formatter.";
    initConfig = {
      configExcludes = [ "**/node_modules" ];
      configKey = "typescript";
      fileExtensions = [
        "ts"
        "tsx"
        "js"
        "jsx"
        "cjs"
        "mjs"
      ];
    };
    pname = "dprint-plugin-typescript";
    updateUrl = "https://plugins.dprint.dev/dprint/typescript/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/typescript-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
