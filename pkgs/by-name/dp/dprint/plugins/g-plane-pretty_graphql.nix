{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "g-plane-pretty_graphql";
  cargoBuildFlags = [
    "-p"
    "dprint_plugin_graphql"
    "--target"
    "wasm32-unknown-unknown"
  ];
}
