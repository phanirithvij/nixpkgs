{
  lib,
  stdenv,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  moreutils,
  jq,
  git,
  writableTmpDirAsHomeHook,
}:

buildGoModule (finalAttrs: {
  pname = "opengist";
  version = "1.11.1";
  src = fetchFromGitHub {
    owner = "thomiceli";
    repo = "opengist";
    tag = "v${finalAttrs.version}";
    hash = "sha256-TlUaen8uCj4Ba2gOWG32Gk4KIDvitXai5qv4PTeizYo=";
  };

  frontend = buildNpmPackage {
    pname = "opengist-frontend";
    inherit (finalAttrs) version src;

    # npm complains of "invalid package". we can give it a version.
    postPatch = ''
      ${lib.getExe jq} '.version = "${finalAttrs.version}"' package.json | ${lib.getExe' moreutils "sponge"} package.json
    '';

    installPhase = ''
      mkdir -p $out
      cp -R public $out
    '';

    npmDepsHash = "sha256-zBao/EoAolkgMvqQPqN0P2VC4tT6gkQPqIk4HyfXC7o=";
  };

  vendorHash = "sha256-NGRJuNSypmIc8G0wMW7HT+LkP5i5n/p3QH8FyU9pF5w=";

  tags = [ "fs_embed" ];

  ldflags = [
    "-s"
    "-X github.com/thomiceli/opengist/internal/config.OpengistVersion=v${finalAttrs.version}"
  ];

  nativeCheckInputs = [
    git
    writableTmpDirAsHomeHook
  ];

  doCheck = !stdenv.hostPlatform.isDarwin;

  checkPhase = ''
    runHook preCheck

    make test

    runHook postCheck
  '';

  postPatch = ''
    cp -R ${finalAttrs.frontend}/public/{.vite/manifest.json,assets} public/
  '';

  passthru = {
    inherit (finalAttrs) frontend;
    updateScript = ./update.sh;
  };

  meta = {
    description = "Self-hosted pastebin powered by Git";
    homepage = "https://github.com/thomiceli/opengist";
    license = lib.licenses.agpl3Only;
    changelog = "https://github.com/thomiceli/opengist/blob/v${finalAttrs.version}/CHANGELOG.md";
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ phanirithvij ];
    mainProgram = "opengist";
  };
})
