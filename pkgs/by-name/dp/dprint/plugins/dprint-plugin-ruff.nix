{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "dprint-plugin-ruff";
  cargoBuildFlags = [
    "--features"
    "wasm"
  ];
}
