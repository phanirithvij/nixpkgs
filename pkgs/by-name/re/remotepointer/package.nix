{
  lib,
  fetchFromGitHub,

  makeWrapper,
  python3,
  qt6,
  stdenvNoCC,

  nix-update-script,
}:

/*
  TODO:
  - bug - svgs not visible, png is
  - fix - svg paths are hardcoded using absolute paths, maybe should be relative paths
  - todo - copy desktop items
  - bug - ctrl+c should kill tray
  - fix - add setup.py and pyproject.toml and use python3.pkgs.buildPythonApplication
  - todo - figure out supported platforms
*/

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "remotepointer";
  version = "3.2";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "schorschii";
    repo = "RemotePointer-Server";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Z92tpF6SZFe9QVaDlg9gaXQztDW8ZYIETqiHTKYIZJg=";
  };

  nativeBuildInputs = [
    qt6.qttools
    makeWrapper
  ];
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/remotepointer
    cp -r lang/ res/ RemotePointerServer.py $out/lib/remotepointer
    makeWrapper ${finalAttrs.passthru.python}/bin/python $out/bin/remotepointer \
      --add-flags "$out/lib/remotepointer/RemotePointerServer.py"

    runHook postInstall
  '';

  passthru = {
    python = python3.withPackages (
      pp: with pp; [
        pyqt6
        pynput
        pyperclip
        psutil
      ]
    );
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Server application for the RemotePointer Android App";
    longDescription = ''
      With RemotePointer you can use your smartphone to control your computer's mouse and keyboard and show a digital laser pointer.
      The goal of this project is to provide an easy-to-use, platform independent, open source remote control application without dependencies to external servers and without tracking.
    '';
    homepage = "https://github.com/schorschii/RemotePointer-Server";
    changelog = "https://github.com/schorschii/RemotePointer-Server/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ phanirithvij ];
    mainProgram = "remotepointer";
    platforms = lib.platforms.all;
  };
})
