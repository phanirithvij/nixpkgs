{
  lib,
  fetchFromGitHub,
  rustPlatform,
  dprint,
  writableTmpDirAsHomeHook,
  callPackage,
  lld,
}:
let
  pluginsData = builtins.fromJSON (builtins.readFile ./plugins.json);

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

  files = lib.filterAttrs (
    name: type:
    type == "regular" && name != "default.nix" && name != "plugins.json" && lib.hasSuffix ".nix" name
  ) (builtins.readDir ./.);

  plugins = lib.mapAttrs' (
    name: _:
    lib.nameValuePair (lib.removeSuffix ".nix" name) (
      callPackage (./. + "/${name}") { inherit mkDprintRustPlugin; }
    )
  ) files;

  getPluginList = cb: map (p: "${p}/plugin.wasm") (cb plugins);
in
plugins // { inherit mkDprintRustPlugin getPluginList; }
