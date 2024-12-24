/*
  TODO remove these later

  https://github.com/NixOS/nixpkgs/issues/354603
  https://nim-lang.org/docs/nims.html
  nitch pacakge drv
  rg -e '\.nims'
*/
{
  lib,
  buildNimPackage,
  fetchFromGitHub,
  gzip,
  pcre2,
  usbutils,
  curl,
  pciutils,
  figlet,
  viu,
}:

buildNimPackage {
  pname = "catnap";
  version = "0-unstable-2024-11-19";
  src = fetchFromGitHub {
    owner = "iinsertNameHere";
    repo = "catnap";
    rev = "268e207ab39d217b6768229e371c9520688a3e68";
    hash = "sha256-o0riYB9nDhMoB3kws5+N7o9XjvAtUb4F3be7fpbSzbo=";
  };

  nativeBuildInputs = [ gzip ];
  runtimeDependencies = [
    pcre2
    usbutils
    figlet
    viu
    curl
    pciutils
  ];

  meta = {
    description = "A highly customizable systemfetch written in nim";
    homepage = "https://github.com/iinsertNameHere/catnap";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ phanirithvij ];
    mainProgram = "catnap";
  };
}
