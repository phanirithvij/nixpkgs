{
  lib,
  fetchurl,
  dprint,
}:
let
  mkDprintPlugin =
    {
      url,
      hash,
      pname,
      version,
      description,
      initConfig,
      updateUrl,
      license ? lib.licenses.mit,
      maintainers ? [ lib.maintainers.phanirithvij ],
      testFile ? null,
    }:
    fetchurl {
      inherit hash url;
      name = "${pname}-${version}.wasm";
      meta = {
        inherit
          description
          license
          maintainers
          ;
      };
      passthru = {
        updateScript = ./update-plugins.py;
        inherit initConfig updateUrl;
      };
      nativeBuildInputs = [ dprint ];
      postFetch =
        if testFile != null then
          ''
            export DPRINT_CACHE_DIR="$(mktemp -d)"
            cd "$(mktemp -d)"
            cp '${testFile}' '${builtins.baseNameOf testFile}'
            dprint check --plugins "$downloadedFile"
          ''
        else
          "";
    };
  inherit (lib)
    filterAttrs
    mapAttrs'
    nameValuePair
    removeSuffix
    ;
  files = filterAttrs (
    name: type: type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name
  ) (builtins.readDir ./.);
  plugins = mapAttrs' (
    name: _:
    nameValuePair (removeSuffix ".nix" name) (import (./. + "/${name}") { inherit mkDprintPlugin; })
  ) files;
in
plugins // { inherit mkDprintPlugin; }
