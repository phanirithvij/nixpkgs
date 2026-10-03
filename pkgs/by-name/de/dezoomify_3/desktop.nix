{
  dezoomify,
  lib,
  stdenv,
  pkg-config,
  rustPlatform,
  python3,
  pnpm,
  pnpmConfigHook,
  fetchPnpmDeps,
  nodejs,
  cargo-tauri,
  wrapGAppsHook4,
  webkitgtk_4_1,
  openssl,
  glib-networking,
  libayatana-appindicator,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dezoomify-desktop";
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

  pnpmDeps = fetchPnpmDeps {
    fetcherVersion = 4;
    inherit (finalAttrs)
      pname
      version
      src
      postPatch
      ;
    hash = "sha256-HRQ+QHV6Q7uBByBD8JB2USRWbyaH6+VoEsnc/qjbQO0=";
  };

  inherit (dezoomify) cargoDeps;

  nativeBuildInputs = [
    pkg-config
    nodejs
    python3
    pnpm
    pnpmConfigHook
    cargo-tauri.hook
    rustPlatform.cargoCheckHook
    rustPlatform.cargoSetupHook
    wrapGAppsHook4
  ];

  buildInputs = [
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    glib-networking
    libayatana-appindicator
    webkitgtk_4_1
  ];

  buildAndTestSubdir = "apps/desktop/src-tauri";

  meta = dezoomify.meta // {
    description = "Dezoomify desktop application";
    mainProgram = "dezoomify";
  };
})
