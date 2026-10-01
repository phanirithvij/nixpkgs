{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "dprint-plugin-jupyter";
  cargoBuildFlags = [
    "--features"
    "wasm"
  ];
}
