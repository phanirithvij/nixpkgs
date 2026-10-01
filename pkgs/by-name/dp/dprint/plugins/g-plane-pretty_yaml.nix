{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "g-plane-pretty_yaml";
  cargoBuildFlags = [
    "-p"
    "dprint_plugin_yaml"
    "--target"
    "wasm32-unknown-unknown"
  ];
}
