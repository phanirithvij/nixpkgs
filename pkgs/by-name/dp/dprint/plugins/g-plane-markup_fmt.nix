{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "g-plane-markup_fmt";
  cargoBuildFlags = [
    "-p"
    "dprint_plugin_markup"
    "--target"
    "wasm32-unknown-unknown"
  ];
}
