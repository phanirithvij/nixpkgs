{
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "nixos-config";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "oddlama";
    repo = "nixos-config-tui";
    rev = "63c17ca88b630e133a32482c63b1c8a3fc161de6";
    hash = "sha256-qIdnjtmoxtUt0SEfeLbcBOwHFsSxbsYn1Th3sK8ub8g=";
  };
  cargoHash = "sha256-muQm/LdCGgrC1WuRQPVh7CEFf87PbZhUoxY+wB1TxTI=";
  meta.mainProgram = "nixos-config";
}
