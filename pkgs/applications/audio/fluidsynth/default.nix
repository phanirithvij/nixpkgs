{ stdenv, lib, fetchFromGitHub, buildPackages, pkg-config, cmake
, alsa-lib, glib, libjack2, libsndfile, libpulseaudio
, AppKit, AudioUnit, CoreAudio, CoreMIDI, CoreServices
}:

stdenv.mkDerivation rec {
  pname = "fluidsynth";
  version = "2.4.3";

  src = fetchFromGitHub {
    owner = "FluidSynth";
    repo = "fluidsynth";
    rev = "v${version}";
    hash = "sha256-LaJcWrHgt/RzlDQmpzOjF/9ugD5d+8XWRt7pU3SM5Rk=";
  };

  outputs = [ "out" "dev" "man" ];

  nativeBuildInputs = [ buildPackages.stdenv.cc pkg-config cmake ];

  buildInputs = [ glib libsndfile libjack2 ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ alsa-lib libpulseaudio ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ AppKit AudioUnit CoreAudio CoreMIDI CoreServices ];

  cmakeFlags = [
    "-Denable-framework=off"
  ];

  meta = with lib; {
    description = "Real-time software synthesizer based on the SoundFont 2 specifications";
    homepage    = "https://www.fluidsynth.org";
    license     = licenses.lgpl21Plus;
    maintainers = with maintainers; [ lovek323 ];
    platforms   = platforms.unix;
    mainProgram = "fluidsynth";
  };
}
