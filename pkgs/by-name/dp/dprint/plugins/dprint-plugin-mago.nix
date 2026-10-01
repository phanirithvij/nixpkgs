{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "dprint-plugin-mago";
  cargoBuildFlags = [
    "--features"
    "wasm"
  ];
}
