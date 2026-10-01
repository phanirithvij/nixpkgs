{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "dprint-plugin-json";
  cargoBuildFlags = [
    "--features"
    "wasm"
  ];
}
