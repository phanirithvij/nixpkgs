{
  dezoomify,
  lib,
  stdenv,
  nodejs,
  pnpm,
  pnpmConfigHook,
  python3,
  rustPlatform,
  pkg-config,
  wasm-bindgen-cli_0_2_128,
  cargo,
  rustc,
  lld,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dezoomify-web";
  inherit (dezoomify) src version;

  postPatch = ''
    python3 -c '
      import json
      with open("package.json") as f:
          d = json.load(f)
      if "pnpm" in d and "overrides" in d["pnpm"]:
          del d["pnpm"]["overrides"]
      with open("package.json", "w") as f:
          json.dump(d, f)
    '
    sed -i '/^overrides:/,/^importers:/ { /^importers:/!d }' pnpm-lock.yaml
  '';

  pnpmDeps = dezoomify.desktop.pnpmDeps;

  inherit (dezoomify) cargoDeps;

  nativeBuildInputs = [
    lld
    nodejs
    pkg-config
    pnpm
    pnpmConfigHook
    python3
    cargo
    rustc
    rustPlatform.cargoCheckHook
    rustPlatform.cargoSetupHook
    wasm-bindgen-cli_0_2_128
  ];

  # cargoSetupHook handles fetching the cargoDeps
  # pnpmConfigHook handles the pnpmDeps

  buildPhase = ''
    runHook preBuild

    # 1. Build the WASM module
    cargo build -p dezoomify-wasm --release --target wasm32-unknown-unknown

    # 2. Run wasm-bindgen
    wasm-bindgen --target web --out-dir wasm --out-name dezoomify-wasm target/wasm32-unknown-unknown/release/dezoomify_wasm.wasm

    # 3. Generate extension vendor mirrors
    node scripts/sync-web-js.mjs

    # 4. Build the site
    node scripts/build-site.mjs

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/dezoomify-web
    cp -r dist/* $out/share/dezoomify-web/

    runHook postInstall
  '';

  meta = dezoomify.meta // {
    description = "Dezoomify web application";
  };
})
