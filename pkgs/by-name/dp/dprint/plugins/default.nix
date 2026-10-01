{
  lib,
  fetchurl,
  fetchFromGitHub,
  rustPlatform,
  rustc,
  stdenv,
  dprint,
  writableTmpDirAsHomeHook,
  callPackage,
}:
let
  mkDprintPlugin =
    {
      pname,
      version,
      description,
      initConfig,
      updateUrl,
      license ? lib.licenses.mit,
      maintainers ? [ lib.maintainers.phanirithvij ],

      # Optional source build info
      owner ? null,
      repo ? null,
      rev ? null,
      hash ? null,
      cargoHash ? null,

      # Optional binary info
      url ? null,
      pos ? null,

      cargoBuildFlags ? [
        "--target"
        "wasm32-unknown-unknown"
        "--features"
        "wasm"
      ],

      ...
    }:
    if cargoHash != null && owner != null then
      rustPlatform.buildRustPackage {
        inherit pos;
        inherit pname version cargoHash;
        src = fetchFromGitHub {
          inherit
            owner
            repo
            rev
            hash
            ;
        };

        nativeBuildInputs = [
          rustc.llvmPackages.lld
        ];

        inherit cargoBuildFlags;

        meta = {
          inherit description license maintainers;
        };

        installPhase = ''
          mkdir -p $out
          WASM_PATH=$(find target/wasm32-unknown-unknown/release -maxdepth 1 -name "*.wasm" | head -n 1)
          cp "$WASM_PATH" $out/plugin.wasm
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
      }
    else
      stdenv.mkDerivation (finalAttrs: {
        inherit pos;
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

  pluginsJson = builtins.fromJSON (builtins.readFile ./plugins.json);

  # For each plugin in plugins.json, load its manual overrides from the respective .nix file
  plugins = lib.mapAttrs (
    pname: data:
    let
      overrides = import (./. + "/${pname}.nix");
    in
    mkDprintPlugin (
      data
      // overrides
      // {
        pos = builtins.unsafeGetAttrPos "pname" overrides;
        maintainers = map (m: lib.maintainers.${m}) (data.maintainers or [ "phanirithvij" ]);
      }
    )
  ) pluginsJson;

  getPluginList = cb: map (p: "${p}/plugin.wasm") (cb plugins);
in
plugins // { inherit mkDprintPlugin getPluginList; }
