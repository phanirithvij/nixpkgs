{
  lib,
  fetchFromGitHub,
  runCommand,
}:

let
  version = "3.0.31";

  # Defined as git clone commands in the *.placeholder.sh files in BBB root
  externalDeps = [
    {
      name = "bbb-etherpad";
      src = fetchFromGitHub {
        owner = "ether";
        repo = "etherpad-lite";
        tag = "1.9.4";
        hash = "sha256-xIwovBrEx9NMI5/v+p6YUAGbv9kMefCqJk+V8x38lvQ=";
      };
    }
    {
      name = "bbb-pads";
      src = fetchFromGitHub {
        owner = "bigbluebutton";
        repo = "bbb-pads";
        tag = "v1.5.11";
        hash = "sha256-a6bCSvrfrfzems5Vzb9P2M9Lb67rUyahL3iTNKKZdDw=";
      };
    }
    {
      name = "bbb-playback";
      src = fetchFromGitHub {
        owner = "bigbluebutton";
        repo = "bbb-playback";
        tag = "v5.4.7";
        hash = "sha256-XL6NwNla+91nzWtmCpS+t0O/npNBEl4XtQAo1jlEe5k=";
      };
    }
    # This is being fetched pre-built, prolly needs extra treatment for our from-source build
    {
      name = "bbb-presentation-video";
      src = fetchFromGitHub {
        owner = "bigbluebutton";
        repo = "bbb-presentation-video";
        tag = "5.1.0-rc.3";
        hash = "sha256-y15VuLW5HrYBu5TQd7PinC+3Xdyi7HePyD5OfOvh+cE=";
      };
    }
    {
      name = "bbb-transcription-controller";
      src = fetchFromGitHub {
        owner = "bigbluebutton";
        repo = "bbb-transcription-controller";
        tag = "v0.2.10";
        hash = "sha256-fRrLF9nKX13rkn/1fLoYSLyFNFu5Md1sOGMlPSvKu/c=";
      };
    }
    {
      name = "bbb-webhooks";
      src = fetchFromGitHub {
        owner = "bigbluebutton";
        repo = "bbb-webhooks";
        tag = "v3.6.0";
        hash = "sha256-VePGB9/JFxArt+ZusA3bBGt2TWdFsTplZ1ttuLQF3Wo=";
      };
    }
    {
      name = "bbb-webrtc-recorder";
      src = fetchFromGitHub {
        owner = "bigbluebutton";
        repo = "bbb-webrtc-recorder";
        tag = "v0.14.0";
        hash = "sha256-KVUFoFvuPhgVAmuFgJU4DnBDiplokfNEj70YM6cOWMQ=";
      };
    }
    {
      name = "bbb-webrtc-sfu";
      src = fetchFromGitHub {
        owner = "bigbluebutton";
        repo = "bbb-webrtc-sfu";
        tag = "v2.22.2";
        hash = "sha256-YUxSNf10otrfJkJhmQ7Fg2gvbk4QyIN0vELhBHl6JMU=";
      };
    }
    {
      name = "freeswitch";
      src = fetchFromGitHub {
        owner = "signalwire";
        repo = "freeswitch";
        tag = "v1.10.12";
        hash = "sha256-uOO+TpKjJkdjEp4nHzxcHtZOXqXzpkIF3dno1AX17d8=";
      };
    }
  ];
  srcBare = fetchFromGitHub {
    owner = "bigbluebutton";
    repo = "bigbluebutton";
    tag = "v${version}";
    hash = "sha256-FYMWHXQNxU8J9FqYpSXaO8VkVGZvvus75LFbhfXqR2k=";
  };
in
runCommand "bigbluebutton-src"
  {
    inherit version;
  }
  ''
    cp -vr ${srcBare} $out
    chmod +w $out

    ${lib.strings.concatMapStringsSep "\n" (dep: "cp -vr ${dep.src} $out/${dep.name}") externalDeps}
  ''
