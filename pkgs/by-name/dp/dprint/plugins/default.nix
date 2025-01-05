{
  lib,
  pkgs,
  fetchurl,
  callPackage,
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
      homepage,
      changelog,
      updateScript ? ./update-plugins.py,
      license ? lib.licenses.mit,
      maintainers ? [ lib.maintainers.phanirithvij ],
    }:
    fetchurl {
      inherit hash url;
      name = "${pname}-${version}.wasm";
      meta = {
        inherit
          description
          license
          maintainers
          homepage
          changelog
          ;
      };
      passthru = {
        inherit initConfig updateUrl updateScript;
      };
      nativeBuildInputs = [ dprint ];
      postFetch = ''
        export DPRINT_CACHE_DIR="$(mktemp -d)"
        cd "$(mktemp -d)"
        dprint check --allow-no-files --plugins "$downloadedFile"
      '';
    };
  inherit (lib)
    filterAttrs
    mapAttrs'
    nameValuePair
    removeSuffix
    ;
  inherit (lib.path) append;
  files = filterAttrs (
    name: type: type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name
  ) (builtins.readDir ./.);
  # gather all plugins as an attrset from plugins/*.nix
  plugins = mapAttrs' (
    name: _:
    nameValuePair (removeSuffix ".nix" name) (callPackage (append ./. name) { inherit mkDprintPlugin; })
  ) files;
in
plugins // { inherit mkDprintPlugin; }
