{ stdenv
, lib
, fetchFromGitHub
, linux-pam
, libxcb
, makeBinaryWrapper
, zig_0_12
, callPackage
}:

stdenv.mkDerivation {
  pname = "ly";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "fairyglade";
    repo = "ly";
    rev = "v1.0.0";
    hash = "sha256-IwZ9QWVrQz/DIIcR4XOW5q54gYDFn5prmujnS3sSquc=";
  };

  nativeBuildInputs = [ makeBinaryWrapper zig_0_12.hook ];
  buildInputs = [ libxcb linux-pam ];

  postPatch = ''
    ln -s ${callPackage ./deps.nix { }} $ZIG_GLOBAL_CACHE_DIR/p
  '';

  meta = with lib; {
    description = "TUI display manager";
    license = licenses.wtfpl;
    homepage = "https://github.com/fairyglade/ly";
    maintainers = [ maintainers.vidister ];
    platforms = platforms.linux;
    mainProgram = "ly";
  };
}
