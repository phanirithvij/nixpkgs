{ mkDprintPlugin, ... }:
let
  version = "v0.11.1";
  hash = "sha256-zt7F1tgPhPAn+gtps6+JB5RtvjIZw2n/G85Bv6kazgU=";
  homepage = "https://github.com/g-plane/malva";
in
mkDprintPlugin (
  {
    description = "CSS, SCSS, Sass and Less formatter.";
    initConfig = {
      configExcludes = [ "**/node_modules" ];
      configKey = "malva";
      fileExtensions = [
        "css"
        "scss"
        "sass"
        "less"
      ];
    };
    pname = "g-plane-malva";
    updateUrl = "https://plugins.dprint.dev/g-plane/malva/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/g-plane/malva-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
