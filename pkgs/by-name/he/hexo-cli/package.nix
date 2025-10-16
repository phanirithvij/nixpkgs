{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage (finalAttrs: {
  pname = "hexo-cli";
  version = "4.3.2";

  src = fetchFromGitHub {
    owner = "phanirithvij";
    repo = "hexo-cli";
    rev = "refs/heads/add-package-lock";
    hash = "sha256-e6wy7/TpGlwXxqSHfSbbuZi5TmoHP9pWZESy2RzR/6Q=";
  };

  npmDepsHash = "sha256-ypijEo2BFvA1lzw6S6FvtRay2gERK0iKVvuWd5rQfUI=";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r bin/ dist/ node_modules/ package.json $out/
    runHook postInstall
  '';

  doInstallCheck = true;
  # versionCheckHook succeeds with a error message, hence a custom install check
  installCheckPhase = ''
    runHook preInstallCheck
    ($out/bin/hexo version 2>/dev/null || true) | grep -F "hexo-cli: ${finalAttrs.version}" \
      || (echo "ERROR: version check failed. expected 'hexo-cli: ${finalAttrs.version}'" && exit 1)
    runHook postInstallCheck
  '';

  meta = {
    changelog = "https://github.com/hexojs/hexo-cli/releases/tag/${finalAttrs.src.tag}";
    description = "Command line interface for Hexo";
    mainProgram = "hexo";
    homepage = "https://hexo.io/";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
