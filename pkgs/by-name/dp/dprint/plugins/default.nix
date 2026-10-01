{
  lib,
  fetchurl,
  stdenv,
  dprint,
  writableTmpDirAsHomeHook,
  callPackage,
}:
let
  pluginsData = builtins.fromJSON (builtins.readFile ./plugins.json);

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
      buildPhase = ''
        mkdir -p $out
        cp $src $out/plugin.wasm
      '';
      doInstallCheck = true;
      nativeInstallCheckInputs = [
        dprint
        writableTmpDirAsHomeHook
      ];
      installCheckPhase = ''
        runHook preInstallCheck

        mkdir empty && cd empty
        dprint check --allow-no-files --config-discovery=false --plugins "$out/plugin.wasm"

        runHook postInstallCheck
      '';
      passthru = {
        updateScript = ./update-plugins.py;
        inherit initConfig updateUrl;
      };
    });

  mkDprintPluginFromJson =
    {
      pname,
      ...
    }@args:
    let
      data = pluginsData.${pname} or (throw "Plugin ${pname} not found in plugins.json");
      pos = builtins.unsafeGetAttrPos "pname" args;
    in
    stdenv.mkDerivation (
      finalAttrs:
      {
        inherit pname pos;
        version = data.version;
        src = fetchurl {
          url = data.url;
          hash = data.hash;
        };
        dontUnpack = true;
        meta = {
          description = data.description;
          license = lib.licenses.mit;
          maintainers = [ lib.maintainers.phanirithvij ];
        };

        buildPhase = ''
          mkdir -p $out
          cp $src $out/plugin.wasm
        '';

        doInstallCheck = true;
        nativeInstallCheckInputs = [
          dprint
          writableTmpDirAsHomeHook
        ];
        installCheckPhase = ''
          runHook preInstallCheck

          mkdir empty && cd empty
          dprint check --allow-no-files --config-discovery=false --plugins "$out/plugin.wasm"

          runHook postInstallCheck
        '';

        passthru = {
          updateScript = ./update-plugins.py;
          initConfig = data.initConfig;
          updateUrl = data.updateUrl;
        };
      }
      // removeAttrs args [ "pname" ]
    );

  inherit (lib)
    filterAttrs
    mapAttrs'
    nameValuePair
    removeSuffix
    ;

  files = filterAttrs (
    name: type:
    type == "regular"
    && name != "default.nix"
    && name != "plugins.json"
    && name != "update-plugins.py"
    && lib.hasSuffix ".nix" name
  ) (builtins.readDir ./.);

  plugins = mapAttrs' (
    name: _:
    nameValuePair (removeSuffix ".nix" name) (
      callPackage (./. + "/${name}") { mkDprintPlugin = mkDprintPluginFromJson; }
    )
  ) files;

  getPluginList = cb: map (p: "${p}/plugin.wasm") (cb plugins);
in
plugins // { inherit mkDprintPlugin getPluginList; }
