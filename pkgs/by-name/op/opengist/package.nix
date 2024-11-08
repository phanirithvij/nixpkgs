{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  moreutils,
  jd-diff-patch,
  jq,
  git,
}:
let
  # finalAttrs when 🥺 (buildGoModule does not support them)
  # https://github.com/NixOS/nixpkgs/issues/273815
  version = "1.8.1";
  src = fetchFromGitHub {
    owner = "thomiceli";
    repo = "opengist";
    rev = "v${version}";
    hash = "sha256-rUE4E5moMujVeN/2obp1LlvyKOPGyP6de1xI/2GdAUc=";
  };
  jd' = lib.getExe jd-diff-patch;
  jq' = lib.getExe jq;
  sponge = "${moreutils}/bin/sponge";

  frontend = buildNpmPackage {
    pname = "opengist-frontend";
    inherit version src;

    # npm complains of "invalid package". shrug. we can give it a version.
    # esbuild optional dependencies installed explicitly
    # as they are missing for non-x86_64-linux in package-lock.json
    # nix shell nixpkgs#{nodejs,jd-diff-patch} -c \
    #   sh -c "npm add -D esbuild@0.18.20; git difftool -yx jd @ -- package-lock.json > package-lock-esbuild.jd.diff"
    prePatch = ''
      ${jq'} '.version = "${version}"' package.json | ${sponge} package.json
      ${jd'} -o package-lock.json -p ${./package-lock-esbuild.jd.diff} package-lock.json || true
      ${jq'} -S . package-lock.json | ${sponge} package-lock.json
    '';

    # copy pasta from the Makefile upstream, seems to be a workaround of sass
    # issues, unsure why it is not done in vite:
    # https://github.com/thomiceli/opengist/blob/05eccfa8e728335514a40476cd8116cfd1ca61dd/Makefile#L16-L19
    postBuild = ''
      EMBED=1 npx postcss 'public/assets/embed-*.css' -c public/postcss.config.js --replace
    '';

    installPhase = ''
      mkdir -p $out
      cp -R public $out
    '';

    npmDepsHash = "sha256-uRocJqRsVqmmndqIJ4MqBussnpfh3bpkYVYxFv38Kpw=";
  };
in
buildGoModule {
  pname = "opengist";
  inherit version src;
  vendorHash = "sha256-B8h+/pUMDzLew0+r2/nTHDcm3Y7Bnwj9R3FzHts6i+k=";
  tags = [ "fs_embed" ];
  ldflags = [
    "-s"
    "-X github.com/thomiceli/opengist/internal/config.OpengistVersion=v${version}"
  ];

  # required for tests
  nativeCheckInputs = [
    git
  ];

  # required for tests to not try to write into $HOME and fail
  preCheck = ''
    export OG_OPENGIST_HOME=$(mktemp -d)
  '';

  checkPhase = ''
    runHook preCheck
    make test
    runHook postCheck
  '';

  postPatch = ''
    cp -R ${frontend}/public/{manifest.json,assets} public/
  '';

  passthru = {
    inherit frontend;
    updateScript = ./update.sh;
  };

  meta = {
    description = "Self-hosted pastebin powered by Git";
    homepage = "https://github.com/thomiceli/opengist";
    license = lib.licenses.agpl3Only;
    changelog = "https://github.com/thomiceli/opengist/blob/master/CHANGELOG.md";
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ phanirithvij ];
    mainProgram = "opengist";
  };
}
