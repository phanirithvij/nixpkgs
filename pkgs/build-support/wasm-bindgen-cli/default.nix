{
  lib,
  rustPlatform,
  fetchCrate,
  nodejs_latest,
  pkg-config,
  openssl,
  stdenv,
  curl,
}:

{
  version ? src.version,
  src,
  cargoDeps,
  meta ? { },
}:

rustPlatform.buildRustPackage {
  pname = "wasm-bindgen-cli";

  inherit version src cargoDeps;

  __structuredAttrs = true;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    curl
  ];

  nativeCheckInputs = [ nodejs_latest ];

  # tests require it to be ran in the wasm-bindgen monorepo
  doCheck = false;

  passthru.updateScript = ./update.sh;

  meta = {
    homepage = "https://wasm-bindgen.github.io/wasm-bindgen/";
    license = lib.licenses.OR [
      lib.licenses.asl20
      lib.licenses.mit
    ];
    description = "Facilitating high-level interactions between wasm modules and JavaScript";
    maintainers = with lib.maintainers; [
      rizary
      insipx
    ];
    mainProgram = "wasm-bindgen";
  }
  // meta;
}
