{
  lib,
  fetchzip,
  nixosTests,
  php,
  stdenv,
  writeText,
}:

stdenv.mkDerivation rec {
  pname = "engelsystem";
  version = "3.6.0";

  src = fetchzip {
    url = "https://github.com/engelsystem/engelsystem/releases/download/v${version}/engelsystem-v${version}.zip";
    hash = "sha256-AZVW04bcSlESSRmtfvP2oz15xvZLlGEz/X9rX7PuRGg=";
  };

  buildInputs = [ php ];

  installPhase = ''
    runHook preInstall

    # prepare
    rm -r ./storage/

    ln -sf /etc/engelsystem/config.php ./config/config.php
    ln -sf /var/lib/engelsystem/storage/ ./storage

    mkdir -p $out/share/engelsystem
    mkdir -p $out/bin
    cp -r . $out/share/engelsystem

    echo $(command -v php)
    # The patchShebangAuto function always used the php without extensions, so path the shebang manually
    sed -i -e "1 s|.*|#\!${lib.getExe php}|" "$out/share/engelsystem/bin/migrate"
    ln -s "$out/share/engelsystem/bin/migrate" "$out/bin/migrate"

    runHook postInstall
  '';

  passthru.tests = nixosTests.engelsystem;

  meta = {
    changelog = "https://github.com/engelsystem/engelsystem/releases/tag/v${version}";
    description = "Coordinate your volunteers in teams, assign them to work shifts or let them decide for themselves when and where they want to help with what";
    homepage = "https://engelsystem.de";
    license = lib.licenses.gpl2Only;
    mainProgram = "migrate";
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.all;
  };
}
