{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "dprint-plugin-markdown";
  cargoBuildFlags = [
    "--features"
    "wasm"
  ];
}
