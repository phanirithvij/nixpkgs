{
  newScope,
  lib,
  sbt,
  jdk17,
  stdenvNoCC,
}:

let
  packages =
    self:
    let
      sbtNix = self.callPackage ./sbt-nix.nix {
        sbt = sbt.override { jre = jdk17; };
      };
      mkSbtDerivation = sbtNix.mkSbtDerivation;
      callPackage = self.newScope {
        inherit mkSbtDerivation;
      };
    in
    {
      ### Things shared between multiple components
      bbb-shared-utils = rec {
        src = callPackage ./src { };

        versionBase = src.version;

        # All components have internal versions, some components are just projects fetched from elsewhere.
        # Don't try tracking every package's version, just add a note whose version this really is.
        versionComponent = "${versionBase}-bigbluebutton";

        postPatch = ''
          patchShebangs build/setup-inside-docker.sh build/packages-template

          # This is for setting up cache persistency in docker across runs. We don't want this.
          substituteInPlace build/setup-inside-docker.sh \
            --replace-fail 'ln -s "''${SOURCE}/cache/''${dir}" "/root/''${dir}"' '#ln -s "''${SOURCE}/cache/''${dir}" "/root/''${dir}"' \
            --replace-fail 'CACHE_DIR="/root/"' 'CACHE_DIR="''${SOURCE}/cache/"'
        '';

        meta = {
          description = "Complete web conferencing system for virtual classes and more";
          homepage = "https://bigbluebutton.org";
          license = lib.licenses.lgpl3Only;
          teams = [
            lib.teams.ngi
          ];
          platforms = lib.platforms.linux;
        };
      };

      ### Individual components
      ### Based on the listing in .github/workflows/automated-tests.yml
      bbb-apps-akka = callPackage ./bbb-apps-akka { };

      bbb-common-message = callPackage ./bbb-common-message { };

      bbb-config = callPackage ./bbb-config { };

      bbb-etherpad = callPackage ./bbb-etherpad { };

      bbb-pads = callPackage ./bbb-pads { };

      bbb-webrtc-recorder = callPackage ./bbb-webrtc-recorder { };

      bbb-webrtc-sfu = callPackage ./bbb-webrtc-sfu { };

      bbb-graphql-server = callPackage ./bbb-graphql-server { };

      bbb-graphql-middleware = callPackage ./bbb-graphql-middleware { };

      bbb-html5 = callPackage ./bbb-html5 { };

      bbb-webhooks = callPackage ./bbb-webhooks { };

      bbb-transcription-controller = callPackage ./bbb-transcription-controller { };

      bbb-playback = callPackage ./bbb-playback { };

      bbb-freeswitch-core = callPackage ./bbb-freeswitch-core { };

      bbb-freeswitch-sounds = callPackage ./bbb-freeswitch-sounds { };

      bbb-fsesl-client = callPackage ./bbb-fsesl-client { };

      bbb-fsesl-akka = callPackage ./bbb-fsesl-akka { };

      bbb-record-core = callPackage ./bbb-record-core { };
    };
in
lib.makeScope newScope (
  self:
  let
    pkgsSet = packages self;
  in
  pkgsSet
  // {
    # TODO make it a simple linkFarm or symlinkJoin
    # is this even useful? the only useful thing would be a nixos module
    all = stdenvNoCC.mkDerivation {
      name = "bigbluebutton-all";
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            n: v:
            if lib.isDerivation v then
              ''
                if [ -d "${v}" ]; then
                  ln -s ${v} $out/${n}
                fi
              ''
            else
              ""
          ) pkgsSet
        )}
      '';
    };
  }
)
