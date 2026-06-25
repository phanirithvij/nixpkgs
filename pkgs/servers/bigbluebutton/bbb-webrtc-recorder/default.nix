{
  lib,
  bbb-shared-utils,
  buildGoModule,
}:

buildGoModule {
  pname = "bbb-webrtc-recorder";
  version = bbb-shared-utils.versionComponent;
  src = "${bbb-shared-utils.src}/bbb-webrtc-recorder";

  vendorHash = "sha256-lI3tqzFuuidSwCwFeLULrpajrBgxHe7PTaGsctKSIXQ=";

  meta = bbb-shared-utils.meta // {
    description = "BigBlueButton WebRTC Recorder";
  };
}
