{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "dprint-plugin-typescript";
  cargoBuildFlags = [
    "--features"
    "wasm"
  ];
}
