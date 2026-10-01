{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "dprint-plugin-toml";
  cargoBuildFlags = [
    "--features"
    "wasm"
  ];
}
