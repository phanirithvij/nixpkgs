{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "dprint-plugin-biome";
  cargoBuildFlags = [
    "--features"
    "wasm"
  ];
}
