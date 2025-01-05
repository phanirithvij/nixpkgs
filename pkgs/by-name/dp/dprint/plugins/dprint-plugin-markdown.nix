{ mkDprintPlugin, ... }:
let
  version = "0.17.8";
  hash = "sha256-PIEN9UnYC8doJpdzS7M6QEHQNQtj7WwXAgvewPsTjqs=";
  homepage = "https://github.com/dprint/dprint-plugin-markdown";
in
mkDprintPlugin (
  {
    description = "Markdown code formatter.";
    initConfig = {
      configExcludes = [ ];
      configKey = "markdown";
      fileExtensions = [ "md" ];
    };
    pname = "dprint-plugin-markdown";
    updateUrl = "https://plugins.dprint.dev/dprint/markdown/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/markdown-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
