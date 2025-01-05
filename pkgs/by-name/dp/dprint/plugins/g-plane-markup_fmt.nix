{ mkDprintPlugin, ... }:
let
  version = "v0.18.0";
  hash = "sha256-G8UnJbc+oZ60V3oi8W2SS6H06zEYfY3wpmSUp+1GF8k=";
  homepage = "https://github.com/g-plane/markup_fmt";
in
mkDprintPlugin (
  {
    description = "HTML, Vue, Svelte, Astro, Angular, Jinja, Twig, Nunjucks, and Vento formatter.";
    initConfig = {
      configExcludes = [ ];
      configKey = "markup";
      fileExtensions = [
        "html"
        "vue"
        "svelte"
        "astro"
        "jinja"
        "jinja2"
        "twig"
        "njk"
        "vto"
      ];
    };
    pname = "g-plane-markup_fmt";
    updateUrl = "https://plugins.dprint.dev/g-plane/markup_fmt/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/g-plane/markup_fmt-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
