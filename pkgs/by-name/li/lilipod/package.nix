{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkgsStatic,
}:

buildGoModule rec {
  pname = "lilipod";
  version = "0.0.3-unstable-2025-02-06";

  src = fetchFromGitHub {
    owner = "89luca89";
    repo = "lilipod";
    rev = "960bb8e0591ec4a2cdfa06050d3cbedf27b35a32";
    hash = "sha256-pSImeXLYZ7jQJWagvkgKVGgjdhd84FiCCozv6m5Ijqs=";
  };

  patches = [ ./busybox_devendor.patch ];

  vendorHash = null;

  ldflags = [ "-s" ];

  buildPhase = ''
    runHook preBuild

    # busybox is embedded inside lilipod via go:embed
    cp ${pkgsStatic.busybox}/bin/busybox .
    RELEASE_VERSION=${version} make all

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    make coverage

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 lilipod $out/bin/lilipod

    runHook postInstall
  '';

  meta = {
    description = "Very simple (as in few features) container and image manager";
    longDescription = ''
      Lilipod is a very simple container manager with minimal features to:

      - Download and manager images
      - Create and run containers

      It tries to keep a somewhat compatible CLI interface with Podman/Docker/Nerdctl.
    '';
    homepage = "https://github.com/89luca89/lilipod";
    license = lib.licenses.gpl3Only;
    mainProgram = "lilipod";
    maintainers = with lib.maintainers; [ aleksana ];
    platforms = lib.platforms.linux;
  };
}
