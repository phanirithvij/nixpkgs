{ mkDprintPlugin, ... }:
mkDprintPlugin {
  changelog = "https://github.com/g-plane/malva/releases/v0.11.1";
  description = "CSS, SCSS, Sass and Less formatter.";
  hash = "sha256-zt7F1tgPhPAn+gtps6+JB5RtvjIZw2n/G85Bv6kazgU=";
  homepage = "https://github.com/g-plane/malva";
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
  url = "https://plugins.dprint.dev/g-plane/malva-v0.11.1.wasm";
  version = "v0.11.1";
}
