{
  lib,
  fetchurl,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  dprint,
  writableTmpDirAsHomeHook,
  callPackage,
  lld,
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
      doInstallCheck = true;
      nativeInstallCheckInputs = [
        dprint
        writableTmpDirAsHomeHook
      ];
      # Prevent schema unmatching errors
      # See https://github.com/NixOS/nixpkgs/pull/369415#issuecomment-2566112144 for detail
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

  mkDprintRustPlugin =
    {
      pname,
      cargoBuildFlags ? [ ],
      ...
    }@args:
    let
      data = pluginsData.${pname} or (throw "Plugin ${pname} not found in plugins.json");
      pos = builtins.unsafeGetAttrPos "pname" args;
    in
    rustPlatform.buildRustPackage (
      {
        inherit pname cargoBuildFlags pos;
        version = data.version;

        src = fetchFromGitHub {
          owner = data.owner;
          repo = data.repo;
          rev = data.rev;
          hash = data.hash;
        };
        cargoHash = data.cargoHash;

        /*
          in the dprint configuration
          dprint expects a plugin path to end with .wasm extension

          for auto update with nixpkgs-update to work
          we cannot have .wasm extension at the end in the nix store path
        */
        buildPhase = ''
          runHook preBuild
          cargo build --release --target wasm32-unknown-unknown ${builtins.concatStringsSep " " cargoBuildFlags}
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp target/wasm32-unknown-unknown/release/*.wasm $out/plugin.wasm
          runHook postInstall
        '';

        nativeBuildInputs = [ lld ];
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

        meta = {
          description = data.description;
          license = lib.licenses.mit;
          maintainers = [ lib.maintainers.phanirithvij ];
        };

        passthru = {
          updateScript = ./update-plugins.py;
          initConfig = data.initConfig;
          updateUrl = data.updateUrl;
        };
      }
      // removeAttrs args [
        "pname"
        "cargoBuildFlags"
      ]
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
      callPackage (./. + "/${name}") { inherit mkDprintRustPlugin; }
    )
  ) files;

  # Expects a function that receives the dprint plugin set as an input
  # and returns a list of plugins
  # Example:
  # pkgs.dprint-plugins.getPluginList (plugins: [
  #   plugins.dprint-plugin-toml
  #   (pkgs.callPackage ./dprint/plugins/sample.nix {})
  # ]
  getPluginList = cb: map (p: "${p}/plugin.wasm") (cb plugins);
in
plugins // { inherit mkDprintRustPlugin mkDprintPlugin getPluginList; }
