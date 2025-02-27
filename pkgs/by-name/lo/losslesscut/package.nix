{
  lib,
  cacert,
  copyDesktopItems,
  electron,
  fetchFromGitHub,
  ffmpeg-full,
  makeDesktopItem,
  makeWrapper,
  mesa,
  nix-update-script,
  writableTmpDirAsHomeHook,
  yarn-berry,
  system,
  stdenvNoCC,
}:
let
  throwSystem = throw "Unsupported system: ${system}";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "losslesscut";
  version = "3.64.0";

  src = fetchFromGitHub {
    owner = "mifi";
    repo = "lossless-cut";
    tag = "v${finalAttrs.version}";
    hash = "sha256-H+tiik78IY6LMG/6dlspiX0CFNTjDxIOhOSE21t7qyA=";
  };

  yarnOfflineCache = stdenvNoCC.mkDerivation {
    name = "losslesscut-${finalAttrs.version}-offline-cache";
    inherit (finalAttrs) src;

    nativeBuildInputs = [
      cacert
      writableTmpDirAsHomeHook
      yarn-berry
    ];

    preConfigure = ''
      yarn config set enableTelemetry false
      yarn config set enableGlobalCache false
      yarn config set supportedArchitectures --json '{"os":["current"], "cpu":["current"], "libc":["current"]}'
      yarn config set cacheFolder $out
    '';

    buildPhase = ''
      runHook preBuild

      yarn install --mode=skip-build

      runHook postBuild
    '';

    outputHashMode = "recursive";
    outputHash =
      {
        x86_64-linux = "sha256-kxAFiYtjTPVeM8FvATQjTizxVdQ0XvxLI7naH6+OXa4=";
        aarch64-linux = "sha256-5L1w85LUWZrtDE3TPIkCOXQiGMqo6fo/opjTU3a7FBU=";
      }
      .${stdenvNoCC.buildPlatform.system} or throwSystem;
  };

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
    mesa
    writableTmpDirAsHomeHook
    yarn-berry
  ];

  postUnpack = ''
    substituteInPlace source/src/main/ffmpeg.ts --replace-fail \
    "function getFfPath(cmd: string) {" \
    "function getFfPath(cmd: string) { return \"${lib.getBin ffmpeg-full}/bin/\" + cmd;} function getFfPath_ORIGINAL(cmd: string) {"

    substituteInPlace source/src/main/i18nCommon.ts --replace-fail \
    "function getLangPath(subPath: string) {" \
    "function getLangPath(subPath: string) { return join(process.env.LOCALES_PATH, subPath);} function getLangPath_ORIGINAL(subPath: string) {"
  '';

  preConfigure = ''
    yarn config set enableTelemetry false
    yarn config set enableGlobalCache false
    yarn config set supportedArchitectures --json '{"os":["current"], "cpu":["current"], "libc":["current"]}'
    yarn config set cacheFolder $yarnOfflineCache
  '';

  buildPhase = ''
    runHook preBuild

    yarn install --mode=skip-build
    yarn run electron-vite build
    yarn run electron-builder --linux --dir \
    -c.electronDist="${electron}/libexec/electron" \
    -c.electronVersion=${electron.version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    makeWrapper "${lib.getExe electron}" $out/bin/losslesscut \
    --inherit-argv0 \
    --add-flags "$out/bin/app.asar" \
    --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
    --set LOCALES_PATH "$out/locales" \
    --set GBM_BACKENDS_PATH "${lib.getLib mesa}/lib/gbm"

    dir="dist/linux-${lib.optionalString stdenvNoCC.hostPlatform.isAarch64 "arm64-"}unpacked"
    cp $dir/resources/app.asar $out/bin
    cp -r $dir/resources/locales $out
    mkdir -p $out/share/pixmaps
    cp icon-build/app-512.png $out/share/pixmaps/losslesscut.png

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      categories = [ "AudioVideo" ];
      comment = "Swiss army knife of lossless video/audio editing";
      desktopName = "LosslessCut";
      exec = "losslesscut %U";
      icon = "losslesscut";
      name = "LosslessCut";
      startupWMClass = "losslesscut";
    })
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Swiss army knife of lossless video/audio editing";
    homepage = "https://github.com/mifi/lossless-cut";
    changelog = "https://github.com/mifi/lossless-cut/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl2Only;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "losslesscut";
    maintainers = with lib.maintainers; [ KSJ2000 ];
  };
})
