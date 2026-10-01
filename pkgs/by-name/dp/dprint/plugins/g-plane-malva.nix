{ mkDprintRustPlugin }:

mkDprintRustPlugin {
  pname = "g-plane-malva";
  cargoBuildFlags = [
    "-p"
    "dprint_plugin_malva"
  ];
}
