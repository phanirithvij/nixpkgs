{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "dprint-plugin-oxc";
  cargoBuildFlags = [
    "--features"
    "wasm"
  ];
}
