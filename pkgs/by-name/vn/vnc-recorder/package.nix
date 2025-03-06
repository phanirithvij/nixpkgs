{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "vnc-recorder";
  version = "0.3.0";
  src = fetchFromGitHub {
    owner = "saily";
    repo = "vnc-recorder";
    rev = "v${version}";
    hash = "sha256-LPgEHphU2yv1r/vJU6o9AZ2WzvX1s+JZJmXFgjNejJI=";
  };
  patches = [ ./unix-socket.patch ];
  vendorHash = "sha256-pJ+AlfHcT8S7YA6wF4j6Owij/DbMzcCvjNX7fJla68g=";
  ldflags = [ "-s" ];
  meta = {
    description = "Record vnc screens to mp4 video using ffmpeg written in go";
    homepage = "https://github.com/saily/vnc-recorder";
    license = lib.licenses.mit;
    mainProgram = "vnc-recorder";
    maintainers = with lib.maintainers; [ phanirithvij ];
  };
}
