{
  lib,
  fetchurl,
  stdenv,
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
    }:
    stdenv.mkDerivation (finalAttrs: {
      inherit pname version;
      src = fetchurl { inherit url hash; };
      dontUnpack = true;
      meta = {
        inherit description license maintainers;
      };
      /*
        in the dprint configuration
        dprint expects a plugin path to end with .wasm extension

        for auto update with nixpkgs-update to work
        we cannot have .wasm extension at the end in the nix store path
      */
      buildPhase = ''
        mkdir -p $out
        cp $src $out/plugin.wasm
      '';
      passthru = {
        updateScript = ./update-plugins.py;
        inherit initConfig updateUrl;
      };
    });
  inherit (lib)
    filterAttrs
    isDerivation
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
  iterPlugins =
    plugins: map (p: "${builtins.toString p}/plugin.wasm") (builtins.filter isDerivation plugins);
  # cb arg: can pass a callback to filter out plugins from nixpkgs or a list of plugins
  withPlugins = cb: iterPlugins (if builtins.isFunction cb then cb plugins else cb);
in
plugins // { inherit mkDprintPlugin iterPlugins withPlugins; }
