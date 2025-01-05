{ pkgs, mkDprintPlugin, ... }:
let
  version = "v0.2.1";
  hash = "sha256-atCb2iS7TJhiX3w5ngf9gmMe3RgghR3MSykwHPxbYLk=";
  homepage = "https://github.com/RubixDev/dprint-plugin-stylua";
in
mkDprintPlugin (
  {
    description = "Format Lua code through dprint using StyLua";
    initConfig = {
      configExcludes = [ ];
      configKey = "stylua";
      fileExtensions = [
        "lua"
      ];
    };
    pname = "rubixdev-stylua";
    updateUrl = "https://plugins.dprint.dev/RubixDev/stylua/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/RubixDev/stylua-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
    license = pkgs.lib.licenses.gpl3Plus;
  }
)
