{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "dprint-plugin-dockerfile";
  cargoBuildFlags = [
    "--features"
    "wasm"
  ];
}
